#!/usr/bin/env bash
set -uo pipefail
for project in tv server; do
  echo "### $project latest-major trial" >> "$GITHUB_STEP_SUMMARY"
  (
    cd "$project" || exit 1
    cp package.json "/tmp/$project-package.json"
    cp package-lock.json "/tmp/$project-package-lock.json"
    if npx --yes npm-check-updates@latest -u --target latest &&
       npm install --package-lock-only --ignore-scripts &&
       npm ci &&
       { if [ "$project" = tv ]; then npm run typecheck && npm test; fi; } &&
       npm run build; then
      echo "Full latest-major update PASSED for $project" >> "$GITHUB_STEP_SUMMARY"
    else
      cp "/tmp/$project-package.json" package.json
      cp "/tmp/$project-package-lock.json" package-lock.json
      echo "Full update incompatible; try packages individually" >> "$GITHUB_STEP_SUMMARY"
      if [ "$project" = tv ]; then
        candidates=("sharp" "vite-plugin-pwa" "puppeteer-core" "lucide")
      else
        candidates=("vite" "laravel-vite-plugin" "@vitejs/plugin-vue" "axios" "vue-i18n" "@vueup/vue-quill" "vue")
      fi
      for dep in "\${candidates[@]}"; do
        cp package.json "/tmp/$project-package.json"
        cp package-lock.json "/tmp/$project-package-lock.json"
        if npx --yes npm-check-updates@latest -u --target latest --filter "$dep" &&
           npm install --package-lock-only --ignore-scripts &&
           npm ci &&
           { if [ "$project" = tv ]; then npm run typecheck && npm test; fi; } &&
           npm run build; then
          echo "Accepted $project dependency $dep" >> "$GITHUB_STEP_SUMMARY"
        else
          cp "/tmp/$project-package.json" package.json
          cp "/tmp/$project-package-lock.json" package-lock.json
          echo "Reverted $project dependency $dep" >> "$GITHUB_STEP_SUMMARY"
        fi
      done
    fi
  ) || exit 1
done
git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git add tv/package.json tv/package-lock.json server/package.json server/package-lock.json
if ! git diff --cached --quiet; then
  git commit -m "Upgrade compatible JS packages to latest tested major versions"
  git push origin HEAD:upgrade/frontend-latest-lab
fi
