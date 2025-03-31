{ pkgs }:

pkgs.writeShellScriptBin "ai-spellcheck" ''
  #!/bin/bash

  # Check if required dependencies are installed
  command -v notify-send >/dev/null 2>&1 || {
      echo "notify-send is not installed. Please install libnotify."
      exit 1
  }
  command -v jq >/dev/null 2>&1 || {
      echo "jq is not installed. Please install jq."
      exit 1
  }
  command -v curl >/dev/null 2>&1 || {
      echo "curl is not installed. Please install curl."
      exit 1
  }
  command -v wl-paste >/dev/null 2>&1 || {
      echo "wl-paste is not installed. Please install wl-paste (or xclip/xsel for X11)."
      exit 1
  }
  command -v wl-copy >/dev/null 2>&1 || {
      echo "wl-copy is not installed. Please install wl-copy (or xclip/xsel for X11)."
      exit 1
  }

  # Check for and source API keys file
  API_KEYS_FILE="$HOME/.cache/api_keys"
  if [ -f "$API_KEYS_FILE" ]; then
      source "$API_KEYS_FILE"
  fi

  # Check if Gemini API key is set (either from environment or from file)
  if [ -z "$GEMINI_API_KEY" ]; then
      notify-send -u critical "Grammar Checker" "Gemini API key is not set. Please set GEMINI_API_KEY environment variable or add it to $API_KEYS_FILE"
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
  TEST_INPUT=$(echo "$INPUT_TEXT" | tr -d '[:space:]')
  if [ -z "$TEST_INPUT" ] || [ "$TEST_INPUT" = "null" ]; then
      notify-send -u critical "Grammar Checker" "No valid text provided to check."
      exit 1
  fi

  # Prepare the prompt for Gemini
  PROMPT="You are a professional bilingual proofreader expert in both German and English. Follow these rules strictly:
  - Fix spelling, grammar, and punctuation errors.
  - Improve clarity and conciseness.
  - Break up overly long sentences for better readability.
  - Remove unnecessary repetition.
  - Convert passive to active voice where appropriate.
  - Use simpler words without changing the meaning.
  - Maintain the original meaning and intent.
  - Keep the same tone of voice and style.
  - Return the text in the same language as the input (German or English).
  - Preserve the original formatting and structure.
  - Return ONLY the corrected text without any explanations.

  Please proofread and correct this text, returning ONLY the corrected version:

  $INPUT_TEXT"

  # Prepare the JSON data for Gemini API
  JSON_DATA=$(jq -n \
      --arg prompt "$PROMPT" \
      '{
          "contents": [
              {
                  "parts": [
                      {
                          "text": $prompt
                      }
                  ]
              }
          ]
      }')

  # Echo the JSON data before making the curl call
  # echo "JSON Data:"
  # echo "$JSON_DATA" | jq .

  # Send request to Gemini API
  RESPONSE=$(echo "$JSON_DATA" | curl \
      -X POST \
      -H "Content-Type: application/json" \
      -H "x-goog-api-key: $GEMINI_API_KEY" \
      --data @- \
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent")

  # Check if the response contains an error.  Improved error checking.
  if echo "$RESPONSE" | jq -e 'has("error")' >/dev/null; then
      ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
      notify-send -u critical "Grammar Checker" "Gemini API error: $ERROR_MSG"
      echo "Full error response:"
      echo "$RESPONSE"
      exit 1
  elif echo "$RESPONSE" | grep -q "Invalid API key"; then
      notify-send -u critical "Grammar Checker" "Gemini API error: Invalid API key. Please check your GEMINI_API_KEY."
      exit 1
  fi

  # Extract the corrected text.  Handles potential null responses.
  CORRECTED_TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text' | sed 's/\\n//g') # added sed to remove newlines

  if [ -z "$CORRECTED_TEXT" ]; then
      notify-send -u warning "Grammar Checker" "Gemini API returned empty response.  Check input and try again."
      CORRECTED_TEXT="$INPUT_TEXT" # keep the original text
  fi
  # Copy corrected text to clipboard
  printf '%s' "$CORRECTED_TEXT" | wl-copy

  # Extract token usage and calculate cost (Note: Gemini API does not directly provide token counts in the same way as OpenAI)
  #  The following section is modified to indicate that token usage is not directly available.
  COST_MSG="Cost: N/A"

  # Send desktop notifications
  notify-send -u normal "Grammar Checker" "Text corrected and copied to clipboard! ($COST_MSG)"

  # Print cost information to terminal
  echo -e "\n=== Usage Statistics ==="
  echo -e "$COST_MSG"
''
