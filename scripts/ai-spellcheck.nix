{ pkgs }:

pkgs.writeShellScriptBin "ai-spellcheck" ''
  # Check if required dependencies are installed
  command -v notify-send >/dev/null 2>&1 || { 
      echo "notify-send is not installed. Please install libnotify."
      exit 1
  }

  # Check if OpenAI API key is set
  if [ -z "$OPENAI_API_KEY" ]; then
      notify-send -u critical "Grammar Checker" "OpenAI API key is not set. Please set OPENAI_API_KEY environment variable."
      exit 1
  fi

  # Function to check input method
  get_input() {
      local input
      if [ -p /dev/stdin ]; then
          # Input is piped
          input=$(cat)
      elif [ $# -gt 0 ]; then
          # Input is provided as arguments
          input="$*"
      else
          # No input, read from clipboard
          input=$(wl-paste)
      fi
      echo "$input"
  }

  # Get input text
  INPUT_TEXT=$(get_input "$@")

  # Check if input is empty
  if [ -z "$INPUT_TEXT" ]; then
      notify-send -u critical "Grammar Checker" "No text provided to check."
      exit 1
  fi

  # Send request to OpenAI API
  RESPONSE=$(curl https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d '{
          "model": "gpt-4o",
          "messages": [
              {
                  "role": "system",
                  "content": "You are a professional proofreader. Return ONLY the corrected text without any additional commentary or explanation. Preserve the original formatting and structure."
              },
              {
                  "role": "user",
                  "content": "Please proofread and correct this text, returning ONLY the corrected version:\n\n'"$(printf '%s' "$INPUT_TEXT" | sed 's/"/\\"/g')"'"
              }
          ],
          "max_tokens": 4096
      }' | jq -r '.choices[0].message.content')

  # Check if response is empty
  if [ -z "$RESPONSE" ]; then
      notify-send -u critical "Grammar Checker" "Failed to get correction from OpenAI API"
      exit 1
  fi

  # Copy corrected text to clipboard
  echo "$RESPONSE" | wl-copy

  # Send desktop notification
  notify-send -u normal "Grammar Checker" "Text corrected and copied to clipboard!"

  # Print original and corrected text
  echo "Original Text:"
  echo "---"
  echo "$INPUT_TEXT"
  echo "---"
  echo ""
  echo "Corrected Response:"
  echo "---"
  echo "$RESPONSE"
  echo "---"
''
