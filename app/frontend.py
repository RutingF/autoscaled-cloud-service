from flask import Flask
import grpc 
import simple_pb2_grpc
import simple_pb2

# frontend Flask app to calls the backend and returns hostname plus backend message
app = Flask(__name__)

# Define the gRPC channel 
channel = grpc.insecure_channel("35.222.33.99:5000") # match this to the output of backend_nlb_ip 
echostub = simple_pb2_grpc.EchoStub(channel)

# call the backend app and returns the hostname plust backend message
@app.route('/hello')
def hello():
    param = simple_pb2.Message(message="HELLO")
    print("PARAM: " + str(param))

    try: 
        retval = echostub.echo(param)
        return retval.message # Extract message from gRPC response 
    except grpc.RpcError as e:
        return "Error: " + str(e) # Return error message

if __name__ == '__main__':
    host = '0.0.0.0' # Listen on all interfaces
    port = 5001 
    print(f"Starting Flask app on {host}:{port}")
    app.run(host=host, port=port, debug=True)
