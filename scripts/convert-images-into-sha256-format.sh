for image in $(cat ./images); do
  no_of_slash=$(echo $image | tr -cd '/' | wc -c)
  prefix=""
  if [ $no_of_slash -eq 1 ]; then
    prefix="docker.io/"
  fi
  if [ $no_of_slash -eq 0 ]; then
    prefix="docker.io/library/"
  fi
  image_to_attest=$image
  if [[ $image =~ "@" ]]; then
    echo "Image $image has DIGEST"
    image_to_attest="${prefix}${image}"
  else
    DIGEST=$(docker pull $image | grep Digest | awk {'print $2'})
    image_name=$(echo $image | awk -F ':' {'print $1'})
    image_to_attest="${prefix}${image_name}@${DIGEST}"
  fi
  escaped_image=$(printf '%s\n' "${image}" | sed -e 's/[]\/$*.^[]/\\&/g')
  escaped_image_to_attest=$(printf '%s\n' "${image_to_attest}" |
    sed -e 's/[]\/$*.^[]/\\&/g')
  echo "Processing $image"
  grep -rl $image ./manifests |
    xargs sed -i "s/${escaped_image}/${escaped_image_to_attest}/g"
done
