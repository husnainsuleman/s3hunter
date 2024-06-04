#!/bin/bash


ffuf -w wordlist/s3.txt:S3  -w wordlist/region.txt:REGION    -u https://S3.s3.REGION.amazonaws.com -mc 200 -v -s  -o ffuf_results.json -of json 

jq -r '.results[] | .url' ffuf_results.json > s3b.txt

output_file="successful_buckets.txt"
> $output_file # Clear previous output file

while IFS= read -r url; do
    echo "Checking bucket: $url"

    # Extract bucket name and region from the URL
    bucket=$(echo "$url" | awk -F'[/.]' '{print $3}')
    region=$(echo "$url" | awk -F'[/.]' '{print $5}')

    # Run aws s3 ls command
    aws s3 ls s3://"$bucket" --no-sign-request --region="$region" >> temp_output.txt 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Success: $url" >> $output_file
        echo "Region: $region" >> $output_file
        cat temp_output.txt >> $output_file
    else
        echo "Failed: $url"
    fi
    rm -f temp_output.txt
done < s3b.txt

echo "Completed. Successful bucket listings are saved in $output_file."
