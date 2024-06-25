# Template

This is a template that can be used to create new Apres terraform modules, with the common attributes and tags
setup as variables with validation. The validation is fairly loose, and may need to be further restricted depending on
the resources created in the module. For example, the ecr_private_repo module `Name` does not allow spaces.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->