RESULT_PATH=$(grep "ResultPath" ./namelist.config \
    | tr -d ' \t' \
    | cut -d'=' -f2- \
    | cut -d'!' -f1 \
    | tr -d " '")

echo "$RESULT_PATH"