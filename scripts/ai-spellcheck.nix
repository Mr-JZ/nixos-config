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

  # Check for and source API keys file
  API_KEYS_FILE="$HOME/.cache/api_keys"
  if [ -f "$API_KEYS_FILE" ]; then
      source "$API_KEYS_FILE"
  fi

  # Check if OpenAI API key is set (either from environment or from file)
  if [ -z "$OPENAI_API_KEY" ]; then
      notify-send -u critical "Grammar Checker" "OpenAI API key is not set. Please set OPENAI_API_KEY environment variable or add it to $API_KEYS_FILE"
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
  echo "Input text: $INPUT_TEXT"
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

  # Check if the response contains an error
  if echo "$RESPONSE" | jq -e 'has("error")' >/dev/null; then
      ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
      notify-send -u critical "Grammar Checker" "OpenAI API error: $ERROR_MSG"
      exit 1
  fi

  # Extract token usage and calculate cost
  PROMPT_TOKENS=$(echo "$RESPONSE" | jq -r '.usage.prompt_tokens')
  COMPLETION_TOKENS=$(echo "$RESPONSE" | jq -r '.usage.completion_tokens')
  TOTAL_TOKENS=$(echo "$RESPONSE" | jq -r '.usage.total_tokens')

  # GPT-4 pricing (as of 2024): $0.03/1K prompt tokens, $0.06/1K completion tokens
  PROMPT_COST=$(echo "scale=4; $PROMPT_TOKENS * 0.03 / 1000" | bc)
  COMPLETION_COST=$(echo "scale=4; $COMPLETION_TOKENS * 0.06 / 1000" | bc)
  TOTAL_COST=$(echo "scale=4; $PROMPT_COST + $COMPLETION_COST" | bc)

  # echo $RESPONSE
  CORRECTED_TEXT=$(echo $RESPONSE | jq -r '.choices[0].message.content')

  # Copy corrected text to clipboard
  # echo "$CORRECTED_TEXT"
  printf '%s' "$CORRECTED_TEXT" | wl-copy

  # Create detailed cost message
  COST_MSG="Tokens used:
  Prompt: $PROMPT_TOKENS ($PROMPT_COST$)
  Completion: $COMPLETION_TOKENS ($COMPLETION_COST$)
  Total: $TOTAL_TOKENS tokens ($TOTAL_COST$)"

  # Send desktop notifications
  notify-send -u normal "Grammar Checker" "Text corrected and copied to clipboard!\n\n$COST_MSG"

  # Print cost information to terminal
  echo -e "\n=== Usage Statistics ==="
  echo -e "$COST_MSG"
''
