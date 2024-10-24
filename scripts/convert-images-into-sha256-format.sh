# This script is already included in .github/workflows/attest-images.yml file, however I wanted to explain it in more detail here.

# The aim of this script is to convert image names which were generated in format {IMAGE_NAME}:{GITHUB_SHA} (For instance -> sba-posts:83047ac) into
# a format that includes docker digest. (For instance _> docker.io/tunacinsoy/sba-frontend@sha256:466ef8f59a7ef5081334c0e4082a2c16f01e251eaa08c94d803aeb0ed9684fd6)
# If the image is retrieved from prebuilt images from dockerhub (like mongo) format becomes like this:
# docker.io/library/mongo@sha256:e64f27edef80b41715e5830312da25ea5e6874a2b62ed1adb3e8f74bde7475a6

# Get all image names from blog-app manifests, and store them in images file.
grep -ir "image:" ../manifests/blog-app |\
awk {'print $3'} | sort -t: -u -k1,1 > ./images

# For each image name in images file:
for image in $(cat ./images); do
  # Get the count of slash character in each image name
  no_of_slash=$(echo $image | tr -cd '/' | wc -c)
  prefix=""
  # If there is only one slash in image name, then it is built by user. (username/image_name)
  if [ $no_of_slash -eq 1 ]; then
    prefix="docker.io/"
  fi
  # If there is not any slash in image name, then it is already built, and was present in dockerhub (mongo:latest)
  if [ $no_of_slash -eq 0 ]; then
    prefix="docker.io/library/"
  fi
  image_to_attest=$image
  if [[ $image =~ "@" ]]; then
  # If image name which was in images file already has @ symbol, then it has sha256 digest in its name
    echo "Image $image has DIGEST"
    image_to_attest="${prefix}${image}"
  else
  # If it does not, then we need to pull its digest from dockerhub
    DIGEST=$(docker pull $image | grep Digest | awk {'print $2'})
    image_name=$(echo $image | awk -F ':' {'print $1'})
    # image_to_attest becomes like this: docker.io/tunacinsoy/sba-frontend@sha256:466ef8f59a7ef5081334c0e4082a2c16f01e251eaa08c94d803aeb0ed9684fd6
    image_to_attest="${prefix}${image_name}@${DIGEST}"
  fi
  # In image names, we need to add \ (backslash) before special characters such as "[]\/$*.^[]"
  # Hence, sed will work correctly while replacing image names with the updated sha256 format.
  escaped_image=$(printf '%s\n' "${image}" | sed -e 's/[]\/$*.^[]/\\&/g')
  escaped_image_to_attest=$(printf '%s\n' "${image_to_attest}" |
    sed -e 's/[]\/$*.^[]/\\&/g')
  echo "Processing $image"
  # Replace image names with the correct format _> (docker.io/tunacinsoy/sba-frontend@sha256:466ef8f59a7ef5081334c0e4082a2c16f01e251eaa08c94d803aeb0ed9684fd6)
  grep -rl $image ../manifests/blog-app |
    xargs sed -i "s/${escaped_image}/${escaped_image_to_attest}/g"
done
