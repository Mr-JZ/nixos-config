{ pkgs }:

pkgs.writeShellScriptBin "ai-spellcheck" ''
  # Check if required dependencies are installed
  command -v notify-send >/dev/null 2>&1 || { 
      echo "notify-send is not installed. Please install libnotify."
      exit 1
  }
  command -v jq >/dev/null 2>&1 || {
      echo "jq is not installed. Please install jq."
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
  # Trim whitespace and check if input is empty, null, or whitespace-only

  # Create a test version of input with all whitespace removed for validation
  TEST_INPUT=$(echo "$INPUT_TEXT" | tr -d '[:space:]')
  if [ -z "$TEST_INPUT" ] || [ "$TEST_INPUT" = "null" ]; then
      notify-send -u critical "Grammar Checker" "No valid text provided to check."
      exit 1
  fi

  # Prepare the JSON data
  JSON_DATA=$(jq -n \
      --arg model "gpt-4" \
      --arg input "$INPUT_TEXT" \
      '{
          "model": $model,
          "messages": [
              {
                  "role": "system",
                  "content": "You are a professional bilingual proofreader expert in both German and English. Follow these rules strictly:\n- Fix spelling, grammar, and punctuation errors\n- Improve clarity and conciseness\n- Break up overly long sentences for better readability\n- Remove unnecessary repetition\n- Convert passive to active voice where appropriate\n- Use simpler words without changing the meaning\n- Maintain the original meaning and intent\n- Keep the same tone of voice and style\n- Return the text in the same language as the input (German or English)\n- Preserve the original formatting and structure\n- Return ONLY the corrected text without any explanations"
              },
              {
                  "role": "user",
                  "content": "Please proofread and correct this text, returning ONLY the corrected version:\n\n\($input)"
              }
          ],
          "max_tokens": 4096
      }')

  # Echo the JSON data before making the curl call
  # echo "JSON Data:"
  # echo "$JSON_DATA" | jq .

  # Send request to OpenAI API
  RESPONSE=$(echo "$JSON_DATA" | curl https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d @-)

  if $RESPONSE | jq -e .error; then
      notify-send -u critical "Grammar Checker" "OpenAI API error: $($RESPONSE | jq -r .error.message)"
      exit 1
  fi

  CORRECTED_TEXT=$($RESPONSE | jq -r .choices[0].message.content)

  notify-send -u critical "Grammar Checker" "Text optimized for readability and clarity."

  echo "$CORRECTED_TEXT" | wl-copy

  # Send desktop notification
  notify-send -u normal "Grammar Checker" "Text corrected and copied to clipboard!"
''
