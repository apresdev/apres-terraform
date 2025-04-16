// This handler runs prior to token generation and tells Cognito to
// copy some of the attributes from the ID token into the access token.
export const handler = function(event, context) {
    const userAttributes = event.request.userAttributes;
    event.response = {
        "claimsAndScopeOverrideDetails": {
            "accessTokenGeneration": {
                "claimsToAddOrOverride": {
                    'email': userAttributes['email'],
                    'custom:tenant': userAttributes['custom:tenant'],
                    'custom:user': userAttributes['custom:user'],
                    'custom:impersonate_tenant': userAttributes['custom:impersonate_tenant'],
                    'custom:impersonate_group': userAttributes['custom:impersonate_group'],
                    'custom:impersonate_email': userAttributes['custom:impersonate_email'],
                    'custom:impersonate_sub': userAttributes['custom:impersonate_sub'],
                    'custom:impersonate_user_id': userAttributes['custom:impersonate_user_id'],
                },
            }
        }
    };
    context.done(null, event);
};
