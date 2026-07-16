#!/bin/sh

LOCKFILE="/app/web/sites/default/files/.lagoon_trial_installed"

if [ -f "$LOCKFILE" ]; then
  echo "Site has already been installed"
elif [ -z "$AI_LLM_API_URL" ]; then
  echo "Please configure the AI_LLM_API_URL variable"
elif [ -z "$AI_LLM_API_TOKEN" ]; then
  echo "Please configure the AI_LLM_API_TOKEN variable"
else
  # Install the site from the bundled demo recipe (config + default content).
  echo "Installing the site from the drupal-org-ai-simplified-text recipe"
  drush -n site:install /app/recipes/drupal-org-ai-simplified-text

  # Install the provider.
  echo "Installing the amazee.io AI provider"

  # Install the provider.
  drush recipe /app/recipes/ai_provider_amazeeio_recipe \
    --input=ai_provider_amazeeio_recipe.llm_host=$AI_LLM_API_URL \
    --input=ai_provider_amazeeio_recipe.llm_api_key=$AI_LLM_API_TOKEN \
    --input=ai_provider_amazeeio_recipe.postgres_db_host=$AI_DB_HOST_NAME  \
    --input=ai_provider_amazeeio_recipe.postgres_db_port=5432  \
    --input=ai_provider_amazeeio_recipe.postgres_db_username=$AI_DB_USERNAME  \
    --input=ai_provider_amazeeio_recipe.postgres_db_password=$AI_DB_PASSWORD  \
    --input=ai_provider_amazeeio_recipe.postgres_db_default_database=$AI_DB_NAME 

  # Demos don't self-update; remove the Update Manager stack so admins don't
  # see "out of date" warnings. Per-module + `|| true` handles both the CMS
  # demos (all three present) and search (only `update`).
  echo "Uninstalling update-manager modules"
  for module in automatic_updates update package_manager; do
    drush -y pm:uninstall "$module" || true
  done

  # Clear the cache
  echo "Rebuilding of the Drupal cache"
  drush cr

  touch $LOCKFILE
  echo "Site install complete."
fi
