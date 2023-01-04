# Foundation Layer - GCP Projects - Development

This is the development environment for iq9.

This Git directory will contain the personal development environments for the dev team members.  Each developer environment gets its own Terraform workspace.  Any cloud services or VM's that are needed in these dev environments will be done via Terraform in the ServiceLayer Git repo, or with manual deployments via the WebUI/CLI.  Because the GCP Projects and GCP Networks are locked down via the Foundation Layer, we are safe in allowing that level of freedom for the developers to deploy to their own personal dev environments since they cannot open any outside access.

Directory contents:

* `Ari_Vatanen_Dev` - contains the development environment for Ari Vatanen
* `Colin_McRae_Dev` - contains the development environment for Colin McRae
