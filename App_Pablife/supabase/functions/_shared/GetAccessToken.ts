import { corsHeaders } from "./cors.ts";
import { generateJWT } from "./GenerateJWT.ts";
import { log } from "./Log.ts";

// Função para obter o token de acesso OAuth2
export async function getAccessToken() {
    const jwt = await generateJWT();
    
    const response = await fetch('https://oauth2.googleapis.com/token',{
        method: 'POST',
        headers: {
            ...corsHeaders,
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams({
            grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            assertion: jwt,
        }),
    });
    
    if (!response.ok) {
        log('Erro ao obter o token de acesso:', response.statusText);
        throw new Error('Erro ao obter o token de acesso'); 
    }
    const data = await response.json(); return data.access_token;
}
