#!/bin/bash

# Set Elasticsearch URL
ES_URL="http://127.0.0.1:9200"

echo "Fixing Elasticsearch cluster health by adjusting replica settings and configuring index templates..."

# Step 1: Create or update the index template with the correct settings
echo "Creating or updating the index template for pattern 'sw_*'..."
curl -X PUT "$ES_URL/_index_template/shopware_template" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["sw_*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    }
  }
}
'

# Step 2: Set the number of replicas to 0 for all existing indices
echo "Updating index settings to set number_of_replicas to 0 for all indices..."
curl -X PUT "$ES_URL/_all/_settings" -H 'Content-Type: application/json' -d'
{
  "index": {
    "number_of_replicas": 0
  }
}
'

# Step 3: Check the cluster health
echo "Checking cluster health..."
curl -X GET "$ES_URL/_cluster/health?pretty"

# Step 4: List all shards to verify status
echo "Listing all shards to check for unassigned replicas..."
curl -X GET "$ES_URL/_cat/shards?v"

echo "Elasticsearch cluster health check, index pattern configuration, and replica adjustment complete."
