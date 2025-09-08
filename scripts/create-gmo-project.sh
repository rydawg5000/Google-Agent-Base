#!/usr/bin/env bash
--billing_account) BILLING_ACCOUNT="$2"; shift 2;;
--folder_id) FOLDER_ID="$2"; shift 2;;
--org_id) ORG_ID="$2"; shift 2;;
--region) REGION="$2"; shift 2;;
--enable_eu_only) EU_ONLY="$2"; shift 2;;
*) echo "Unknown flag $1"; exit 1;;
esac
done


if [[ -z "$PROJECT_ID" || -z "$BILLING_ACCOUNT" ]]; then
echo "project_id and billing_account are required"; exit 1
fi


# 1) Create project
if [[ -n "$FOLDER_ID" ]]; then
gcloud projects create "$PROJECT_ID" --folder="$FOLDER_ID"
elif [[ -n "$ORG_ID" ]]; then
gcloud projects create "$PROJECT_ID" --organization="$ORG_ID"
else
gcloud projects create "$PROJECT_ID"
fi


gcloud beta billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT"


echo "✅ Project created and linked to billing: $PROJECT_ID"


# 2) Set default project
gcloud config set project "$PROJECT_ID"


# 3) Enable base APIs (extend as needed)
APIS=(
serviceusage.googleapis.com
iam.googleapis.com
iamcredentials.googleapis.com
run.googleapis.com
artifactregistry.googleapis.com
compute.googleapis.com
secretmanager.googleapis.com
cloudbuild.googleapis.com
logging.googleapis.com
bigquery.googleapis.com
firestore.googleapis.com
aiplatform.googleapis.com
cloudscheduler.googleapis.com
documentai.googleapis.com
)
for api in "${APIS[@]}"; do
gcloud services enable "$api" --project "$PROJECT_ID"
done


echo "✅ Core APIs enabled"


# 4) Terraform state bucket (regional, versioned)
STATE_BUCKET="${PROJECT_ID}-tf-state"
gsutil mb -l "$REGION" -p "$PROJECT_ID" "gs://${STATE_BUCKET}/"
gsutil versioning set on "gs://${STATE_BUCKET}"
echo "terraform { backend \"gcs\" { bucket = \"${STATE_BUCKET}\" prefix = \"infra\" } }" > infra/backend.tf


echo "✅ TF state bucket created: gs://${STATE_BUCKET}"


# 5) Optional org policy (EU-only) — skip if no permission
if [[ "$EU_ONLY" == "true" ]]; then
cat > infra/policies/org_eu_locations.yaml <<'YAML'
constraint: constraints/gcp.resourceLocations
listPolicy:
suggestedValue: in:eu-locations
allowedValues:
- in:eu-locations
YAML
echo "⚠️ Apply org policy at org/folder level manually if required. File written to infra/policies/org_eu_locations.yaml"
fi


echo "✅ Bootstrap complete. Next: cd infra && terraform init && terraform apply -var=project_id=${PROJECT_ID} -var=region=${REGION}"
