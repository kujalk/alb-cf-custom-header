How to build lambda code 
-----------------------------

$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"
go build lambda.go
~\Go\Bin\build-lambda-zip.exe -o myFunction.zip lambda
