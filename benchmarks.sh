echo "Insertion benchmark..."
mix run bench/insert_benchmark.ex

echo "Query benchmark..."
mix run bench/query_benchmark.ex

echo "Update benchmark..."
mix run bench/update_benchmark.ex

echo "Erase benchmark..."
mix run bench/delete_benchmark.ex