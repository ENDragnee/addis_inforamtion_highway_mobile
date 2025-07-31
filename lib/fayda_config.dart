
// lib/fayda_config.dart

const String clientId = 'YOUR_CLIENT_ID'; // PLEASE REPLACE WITH YOUR CLIENT ID
const String redirectUri = 'com.example.app:/oauth2redirect'; // PLEASE REPLACE WITH YOUR REDIRECT URI

const String authorizationEndpoint = 'https://ida.fayda.et/am/oauth2/authorize';
const String tokenEndpoint = 'https://ida.fayda.et/am/oauth2/token';
const String userinfoEndpoint = 'https://ida.fayda.et/am/oauth2/userinfo';

const String algorithm = 'PS256';
const String clientAssertionType = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer';
