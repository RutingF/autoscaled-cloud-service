# Autoscaled-Cloud-Service
An autoscaled cloud service leveraging GCP (Google Cloud Platform): 
- **Backend**: A **gRPC-based** microservice for internal communication. 
- **Frontend**: A **Flask-based** web application.
- **Infrastructure**: Uses **Terraform** to provision cloud resources, including internal and external **load blancers**. 


## Infrastructure 
This repo uses **Terraform** to provision cloud infrastructure on GCP, including **Network Load Balancer** and **Application Load Balancer**. 

To deploy the infrastructure, run the following commands: 
```sh
terraform init
terraform apply
```

To tear down the infrastructure:
```sh
terraform destroy
```

## Backend 

Backend service utlizes **gRPC** to enable communication between **distributed systems**, and designed to work with **Network Load Balancers**. 

### Steps for Running the Backend: 

Before using the gRPC backend, **run the following command in the root directory:**
```sh
python -m grpc_tools.protoc -I./protos --python_out=./app --grpc_python_out=./app protos/simple.proto
```
This will generate files 'simple_pb2.py' and 'simple_pb2_grpc.py' in the app directory.

Note: you need to install the grpc tools:
```sh
   python -m pip install grpcio
   python -m pip install grpcio-tools
```




