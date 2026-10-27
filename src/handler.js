module.exports.hello = (event, context, callback) => {
		const response = {
				"statusCode": 200,
				"headers": {},
				"body": 'hello world'
		}
		callback(null, response);
};

module.exports.whoami = (event, context, callback) => {
		const principalId = event.requestContext && event.requestContext.authorizer && event.requestContext.authorizer.principalId;
		const response = {
				"statusCode": 200,
				"headers": {},
				"body": principalId || ''
		}
		callback(null, response);
};
