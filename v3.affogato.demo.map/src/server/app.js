const express = require("express")
const k8s = require('@kubernetes/client-node');
const os = require("os")
const app = express()
const port = 3000

const kc = new k8s.KubeConfig();
kc.loadFromDefault();

app.get("/", (req, res) => {
	res.send(kc.contexts)

});

app.get("/api/contexts", (req, res) => {
	let contexts = []
	kc.contexts.forEach(c=> {
		contexts.push(c.name);
	});
	res.send(contexts)
});

app.get("/api/nodes", (req, res) => {

	const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
	k8sApi.listNode()
		.then((d) => {
			res.send(d.body.items)
		});

});

app.get("/api/namespaces", (req, res) => {

	const k8sApi = kc.makeApiClient(k8s.CoreV1Api);
	k8sApi.listNamespace()
		.then((d) => {
			let namespaces = []
			d.body.items.forEach(ns=> {
				namespaces.push(ns.metadata.name)
			});
			res.send(namespaces)
		});

});


app.listen(port, () => {
	console.log(`started listening at http://localhost:${port}`)
})