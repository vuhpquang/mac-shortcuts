#!/bin/bash
QUESTION="$1"
echo ""
echo "╔══════════════════════════════════════╗"
echo "║  STAKEHOLDER INPUT REQUIRED          ║"
echo "╚══════════════════════════════════════╝"
echo "Question: $QUESTION"
echo ""
read -p "Your answer: " ANSWER
node -e "
const fs = require('fs');
const bb = JSON.parse(fs.readFileSync('./blackboard/state.json'));
bb.decisions.push({ question: process.argv[1], answer: process.argv[2], timestamp: Date.now() });
bb.stakeholder_queue = [];
fs.writeFileSync('./blackboard/state.json', JSON.stringify(bb, null, 2));
" "$QUESTION" "$ANSWER"
echo "$ANSWER"
