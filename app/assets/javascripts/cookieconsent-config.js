import 'https://cdn.jsdelivr.net/gh/orestbida/cookieconsent@3.0.1/dist/cookieconsent.umd.js';

CookieConsent.run({

    categories: {
        necessary: {
            enabled: true,  // this category is enabled by default
            readOnly: true  // this category cannot be disabled
        },
        analytics: {
            autoClear: {
                cookies: [
                    {
                        name: /^(_ga)/      //regex
                    },
                    {
                        name: '_gid'        //string
                    }
                ]
            }
        }
    },

    language: {
        default: 'en',
        translations: {
            en: {
                consentModal: {
                    title: 'We use cookies',
                    description: 'These cookies help us to improve your experience by providing insights into how the site is being used. For more detailed information please check our Privacy Policy',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject non-essential',
                    showPreferencesBtn: 'Manage Individual preferences'
                },
                preferencesModal: {
                    title: 'Manage cookie preferences',
                    acceptAllBtn: 'Accept all',
                    acceptNecessaryBtn: 'Reject non-essential',
                    savePreferencesBtn: 'Accept current selection',
                    closeIconLabel: 'Close modal',
                    sections: [
                        {
                            title: 'Essential cookies',
                            description: 'Essential cookies enable core functionality. The website cannot function properly without these cookies, and can only be disabled by changing your browser preferences.',

                            //this field will generate a toggle linked to the 'necessary' category
                            linkedCategory: 'necessary'
                        },
                        {
                            title: 'Performance and Analytics',
                            description: 'Analytical cookies help us to improve our website by collecting and reporting information on its usage.',
                            linkedCategory: 'analytics'
                        },
                        {
                            title: 'More information',
                            description: 'For more detailed information please check our <a href="https://dri.ie/privacy-policy">privacy policy.</a>'
                        }
                    ]
                }
            }
        }
    }
});
