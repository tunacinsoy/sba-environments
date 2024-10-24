This repository sets up a Google Cloud Platform (GCP) environment with infrastructure automation using Terraform, GitHub Actions for CI/CD, and Kubernetes for application orchestration. It includes the deployment of a GKE cluster, ArgoCD for GitOps, and Istio for service mesh management.

Additionally, you'll find the Traffic Mirroring Strategy through Istio VirtualService manifests, and monitoring tools like Prometheus, Grafana, Jaeger, and Kiali for observability purposes.

#### Step by Step Explanation

```bash
# Clone the repo (you'll be in prod branch by default, however we do not want to operate there)
git clone https://github.com/tunacinsoy/sba-environments

# And checkout to dev branch
git checkout dev
```
---
```bash
# configure gcloud settings, including favorite region/zone selection, which project we are operating on etc.
gcloud init
```
---
```bash
# Enable necessary APIs
gcloud services enable iam.googleapis.com \
container.googleapis.com \
binaryauthorization.googleapis.com \
containeranalysis.googleapis.com \
secretmanager.googleapis.com \
cloudresourcemanager.googleapis.com \
cloudkms.googleapis.com \
serviceusage.googleapis.com
```
---
```bash
# Create service account for terraform, add iam policy (container.admin is required for the operations on gke cluster, such as deploying argocd using kubectl provider; and also cryptoOperator is necessary for accessing public key in cloud KMS), and retrieve the credentials in a file named key-file.

PROJECT_ID=<project_id>
gcloud iam service-accounts create terraform \
--description="Service Account for Terraform" \
--display-name="Terraform"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" --role="roles/cloudkms.cryptoOperator"

gcloud iam service-accounts keys create key-file \
--iam-account=terraform@$PROJECT_ID.iam.gserviceaccount.com

#Optional
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/key-file.json" 

```
---
```bash
# After the previous step, `key-file` file will be generated, and go to GitHub Secrets page and set the `GCP_CREDENTIALS` value as that. This will be our service account credentials for terraform to do operations on GCP.
# Then, create another secret called `PROJECT_ID` and set it as your project_id. These values will be used during the workflow (CI/CD) processes.

GCP_CREDENTIALS=<content of key-file>
PROJECT_ID=<project_id>
DOCKER_USER=<docker_username>
DOCKER_PASSWORD=<docker_password>

```
---
```bash
# For binary authorization to work, set these values as well on GitHub Secrets
ATTESTOR_NAME=quality-assurance-attestor 
KMS_KEY_LOCATION=us-central1 
KMS_KEYRING_NAME=qa-attestor-keyring 
KMS_KEY_NAME=quality-assurance-attestor-key 
KMS_KEY_VERSION=1
```
---
```bash
# Create a gcs bucket for the storage of terraform backend files
gcloud storage buckets create gs://<gcs_bucket_name tf-state-sba-terraform-${PROJECT_ID}> --location=<location europe-central2>
```
---

Since our dev-cd-workflow.yaml file creates an auto merge request to prod branch, we need to generate a token first.
1. Go to https://github.com/settings/personal-access-tokens/new.
2. Create a new token with “Repository” access for the sba-environments repository, granting it read-write pull request permissions. This approach aligns with the principle of least privilege, offering more granular control.
3. Once the token is created, copy it.
4. Now, create a GitHub Actions secret named `GH_TOKEN` and paste the copied token as the value.
---

Delete the mongodb-creds-sealed.yaml file from path `sba-environments/manifests/blog-app/mongodb-creds-sealed.yaml` because we will generate it after we deploy the sealed secrets controller to our GKE cluster.

---

Uncomment `dev-cd-workflow.yaml` file, and push the changes into dev branch. This will initiate the deployment process of infrastructure using terraform, and terraform will create GKE cluster, and then with the `kubectl` plugin, it will apply manifest files for the ArgoCD installation, and apply all manifest files listed under `path: manifests/*`. This means that with a single `git push` operation, we will have our fully fledged infrastructure.

---

```bash

# Retrieve the external IP addr of argocd (type load balancer)
kubectl get svc -n argocd

# After initial deployment of argocd, default password is generated. With these commands, we are creating new password for the log-in.

kubectl patch secret argocd-secret -n argocd \
-p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'

# This effectively clears the admin password, triggering Argo CD to regenerate it the next time the `argocd-server` starts.
kubectl scale deployment argocd-server --replicas 0 -n argocd

kubectl scale deployment argocd-server --replicas 1 -n argocd

kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d && echo

# Copy the password, and navigate to the argocd portal using the obtained link, and log in there with username admin and newly generated password

```
---
We would see that our app does not work, since we haven't set up our secrets for our microservices to access mongodb. To do so:

```bash
# In order to seal a secret using sealedSecrets, following cmd sequence should be used
kubectl create secret generic mongodb-creds \
--dry-run=client -o yaml --namespace=blog-app \
--from-literal=MONGO_INITDB_ROOT_USERNAME=rootAdmin \
--from-literal=MONGO_INITDB_ROOT_PASSWORD=P433sw0rd123! \
| kubeseal -o yaml > mongodb-creds-sealed.yaml

# After the deployment, we might need to scale down statefulsets and deployments using following command:
kubectl scale statefulset -n blog-app mongodb --replicas 0
kubectl scale statefulset -n blog-app mongodb --replicas 1

```
And once we deploy this manifest file, it will deploy the secret named `mongodb-creds`, which is only can be decrypted by sealed-secrets controller. 

---
```bash
# After we see that our blog-app turns into green on argocd portal, we can obtain the istio ingress external ip.
kubectl get svc -n istio-system

```
Once we navigate to the IP address, we'll see our application working fine.
