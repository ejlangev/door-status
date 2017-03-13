export LAMBDA_FUNCTION_NAME=<YOUR LAMBDA FUNCTION>
export AWS_PROFILE=<PROFILE INFO>
export S3_BUCKET=<S3 BUCKET>

.PHONY: build-server
build-server:
	cd server && zip -r lambda-code.zip node_modules/ index.js > /dev/null

.PHONY: update-server
update-server: build-server
	aws lambda update-function-code --zip-file fileb://server/lamda-code.zip --function-name $LAMBDA_FUNCTION_NAME $AWS_PROFILE


.PHONY: update-frontend
update-frontend:
	aws s3 cp --acl public-read frontend/index.html s3://$S3_BUCKET/ $AWS_PROFILE
