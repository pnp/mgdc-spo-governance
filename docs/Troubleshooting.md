# Troubleshooting

If your pipeline run failed, click on the pipeline run which will open the pipeline activity list. Hover over the activity that failed and click on the error message icon. This will open the error message.

![Pipeline Error](/docs/res/OFPipelineError.png)

This error may be difficult to diagnose, feel free to raise an issue on the repo with a screenshot of your error to get support.

Some common errors below are detailed.

## Notebook Error

Difficult to resolve unless you open up and read through the notebook.

## MGDC Error

Easier to diagnose as MGDC normally returns a good description of the error

Likely due to missing dataset permission on the MGDC app. The example below states that the Files dataset is not available to the tenant. This is because it was enrolled into private preview of the Files dataset.

![MGDC Pipeline Error](/docs/res/TroubleshootingMGDCError.png.png)




