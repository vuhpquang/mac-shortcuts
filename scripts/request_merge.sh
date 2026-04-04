#!/bin/bash
PROJECT=$1
cd ./projects/$PROJECT
echo ""
echo "╔══════════════════════════════════════╗"
echo "║  READY TO MERGE develop → main       ║"
echo "╚══════════════════════════════════════╝"
git log develop --oneline --not main
echo ""
read -p "Approve merge to main? (y/n): " APPROVE
if [ "$APPROVE" = "y" ]; then
  git checkout main
  git merge --no-ff develop -m "release: approved by stakeholder"
  git checkout develop
  echo "Merged to main successfully."
else
  echo "Merge rejected."
fi
