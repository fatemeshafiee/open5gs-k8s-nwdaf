#!/bin/bash

for i in {1..12}; do
    echo "▶️ Running eval for interval_5_round_$i"
    ./eval_nwdaf_attack.sh interval_5_round_$i

    if [ $? -ne 0 ]; then
        echo "❌ Script failed at round $i"
        break
    fi
done

echo "✅ All evaluations completed."
