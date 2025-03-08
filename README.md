# WKHTMLTOPDF Lambda Layer Build Instructions

This document explains how to create a Lambda layer containing the wkhtmltopdf binary and its required libraries using a Docker container. The resulting ZIP file should be uploaded to S3 and the CloudFormation template (`100_layer.cf.yaml`) should be updated accordingly.

## Prerequisites

- **Docker**: Ensure Docker is installed and running on your machine.
- **Fonts**: Place any required fonts in the `fonts/` directory.
- **Build Script**: The `build_lambda_layer.sh` script must be present in the root directory.

## Building the Lambda Layer

Run the following Docker command from the `wkhtmltopdf-layer` directory:

```bash
docker run --rm \
  -v "$(pwd)/output":/output \
  -v "$(pwd)/fonts":/build/fonts \
  -v "$(pwd)/build_lambda_layer.sh":/build/build_lambda_layer.sh \
  -w /build \
  -it \
  --platform=linux/amd64 \
  amazonlinux:2023 \
  bash ./build_lambda_layer.sh
```

## Post build steps

- Upload to S3: Once the ZIP file is created in the output/ directory, upload it to your S3 bucket.
- Update CloudFormation Template: Update your CloudFormation template to point to the new S3 object. This ensures that the Lambda functions can use the updated layer.
- Update the relevant SAM templates to use the new layer

## Additional notes

- Testing: Before updating production resources, test the Lambda layer in a development environment.
- Dependencies: Ensure that all required C libraries for wkhtmltopdf are packaged within the layer.
- Troubleshooting: If you encounter any issues during the build, verify that your Docker environment is correctly configured and that all paths in the command are accurate.
