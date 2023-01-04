# Demo for k6-operator
Demo files for the [_"Running distributed load tests with k6"_](https://www.meetup.com/kubernetes-cloud-native-stl/events/288633674/), 
originally presented to the _Kubernetes & Cloud Native STL_ meetup group.

## Prerequisites
* [git](https://git-scm.com/) - For accessing the sourcecode repositories.
* [Docker](https://docs.docker.com/get-docker/) - For building our custom k6 and running the examples.
* [kubectl](https://kubernetes.io/releases/download/#kubectl) - Client for talking to Kubernetes clusters.
* [go](https://go.dev/doc/install) - To build and install k6-operator.
* [Yq](https://mikefarah.gitbook.io/yq/) - Just for the helper scripts to parse YAML files.

There _may_ be others that I didn't recall as having them installed long ago. My apologies for any issues!


## Create a local Kubernetes cluster (optional)
I'm using [k3d](https://k3d.io/) locally to run a _Kubernetes_ cluster within _Docker_. Once installed, I use 
the following command to create a cluster named `k6-demo-cluster`.

```shell
k3d cluster create k6-demo-cluster \
 --api-port 6550 \
 -p "8081:80@loadbalancer" \
 --agents 3 \
 --k3s-arg '--kube-apiserver-arg=feature-gates=EphemeralContainers=true@server:*'
```
> :point-right: If you've previously created the cluster, you can start the cluster using `k3d cluster start k6-demo-cluster`
> if not already running.

Once this is complete, I now have a running Kubernetes cluster on which I can use `kubectl` as well as other tooling 
like [k9s](https://k9scli.io/).


## Build and install the k6-operator
> :thumbsup: Always ensure your `kubectl` is set to the appropriate profile targeting the correct cluster!

For housekeeping purposes, we'll clone the k6-operator source code into our `dependencies` directory. 

```shell
# Pull down the operator which we'll install into Kubernetes.
git clone git@github.com:grafana/k6-operator.git dependencies/k6-operator
```

Now we'll build and install directly from the source code.

```shell
# Change into the k6-operator source directory. (You downloaded this in the first step!)
cd dependencies/k6-operator
make deploy
cd ../..

```
> :warning: There may be an issue with the version of Kube you're running. Newer versions will need to remove
> the `trivialVersions` flag from the `CRD_OPTIONS` defined in [k6-operator/Makefile](https://github.com/grafana/k6-operator/blob/main/Makefile#L21).

At this point, the operator and applicable resource definition have been installed into your Kubernetes cluster.


## Resource setup
Now that we have a working Kubernetes cluster, let's create an isolated _Namespace_ and add our
example test scripts as a _ConfigMap_.

```shell
# Let's create an isolated namespace for our testing
kubectl create namespace k6-demo

# Create a ConfigMap containing each of your test scripts
kubectl create configmap test-scripts -n k6-demo \
 --from-file=./test-scripts/simple.js \
 --from-file=./test-scripts/simple-checks.js \
 --from-file=./test-scripts/multi-scenario.js \
 --from-file=./test-scripts/door-buster-sale.js
```

### Grafana Cloud
For my demonstration, I'm using the _Free Forever Cloud_ from [Grafana Cloud](https://grafana.com/products/cloud/)
which will receive Prometheus metrics during test executions. 

Once signed up, update the Prometheus endpoint, user, and password (api-key) placeholders for your account in the
following commands.

```shell
# Create a ConfigMap with our non-secret configuration for our cloud account
kubectl create configmap -n k6-demo prometheus-config \
 --from-literal=K6_PROMETHEUS_RW_SERVER_URL=[YOUR REMOTE WRITE ENDPOINT]

# Create a secret with our authentication data for our cloud account
kubectl create secret -n k6-demo generic prometheus-secrets \
 --from-literal=K6_PROMETHEUS_RW_USERNAME=[YOUR USERNAME] \
 --from-literal=K6_PROMETHEUS_RW_PASSWORD=[YOUR PASSWORD] 
```

### Grafana k6 Cloud
Not only can we use the Grafana _Free Forever Cloud_, but we can also sign up to use the 
[Grafana k6 Cloud](https://app.k6.io/account/register) offering for the _same low price_ (FREE)! 

After signing up, update the project ID and api-key placeholders below then create your 
Kubernetes secret.

```shell
kubectl create secret -n k6-demo generic k6-cloud-secrets \
 --from-literal=K6_CLOUD_PROJECT_ID=[YOUR PROJECT ID]
 --from-literal=K6_CLOUD_TOKEN=[YOUR K6 API KEY]
```

Now that we have our necessary resources available in Kubernetes, we can trigger a test execution.


## Running a distributed test
To perform a distributed test, you simply apply the k6 custom resource definition (CRD) to your
Kubernetes cluster using the standard `kubectl` tool.

```shell
# Adds the k6 CRD to trigger an test execution
kubectl apply -n k6-demo -f resources/k6-output-grafana-cloud.yaml
```
Once you've finished up, you can clear previous executions from your Kubernetes cluster in order
to run the same script again.
```shell
# Post-test cleanup paves way for next test execution
kubectl delete -n k6-demo -f resources/k6-output-grafana-cloud.yaml
```
:thumbsup: My dashboard example makes use of a custom `testid` tag to keep track of each test run.
For this, I use the convenience script `run-kube.sh` which will add a unique timestamp to keep
each test execution separate. This script will also replace a previous execution of the test resource
if one already existed.
```shell
# Removes previous execution (if any), then run test with a unique `testid`
./run-kube.sh resources/k6-output-grafana-cloud.yaml
```
:point_right: The same process can be used to publish metrics to the _Grafana k6 Cloud_ by running 
the [k6-output-k6-cloud.yaml](resources/k6-output-k6-cloud.yaml) instead.

> :warning: By default, the free-tier subscription for k6 Cloud will only allow for parallel execution,
> nor multiple scenarios.
