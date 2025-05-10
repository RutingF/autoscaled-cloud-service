import grpc
from concurrent import futures
import simple_pb2
import simple_pb2_grpc
import socket

# Define a class that extends simple_pb2_grpc.EchoServicer, which is generated from the proto file.

class EchoService(simple_pb2_grpc.EchoServicer):
    def echo(self, request, context):
        hostname = socket.gethostname()
        return simple_pb2.Message(message=f"Backend ({hostname}) received: {request.message}")

# Define a function that starts the gRPC server and listens on port 5000.

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    simple_pb2_grpc.add_EchoServicer_to_server(EchoService(), server)
    server.add_insecure_port("[::]:5000")  # gRPC on port 5000
    print("Starting gRPC backend on port 5000...")
    server.start()
    server.wait_for_termination()

if __name__ == "__main__":
    serve()
