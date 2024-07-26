# Scheduling Utils

Azure Synapse Studio supports scheduling of pipelines. However we need to dynamically change our pipeline parameters at each run. This is not supported. To be able to trigger the pipeline with dynamic parameters on a schedule we need to make use of the synapse REST APIs.