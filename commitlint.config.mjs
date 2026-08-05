export default {
	extends: ['@commitlint/config-conventional'],
	rules: {
		// Disable body line length check
		'body-max-line-length': [0, 'always'],
	}
};