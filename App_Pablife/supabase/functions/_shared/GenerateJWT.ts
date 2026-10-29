import * as jose from 'https://deno.land/x/jose@v4.8.3/index.ts';

export async function generateJWT() {
    const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n');
    const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL');
    // const projectId = Deno.env.get('FIREBASE_PROJECT_ID');

    if (!privateKey || !clientEmail) {
        throw new Error('FIREBASE_PRIVATE_KEY or FIREBASE_CLIENT_EMAIL is not set in environment variables');
    }
    
    const jwt = new jose.SignJWT({
        "iss": clientEmail,
        "sub": clientEmail,
        "aud": "https://oauth2.googleapis.com/token",
        "scope": "https://www.googleapis.com/auth/firebase.messaging",
    }).setProtectedHeader({ alg: 'RS256' })
    .setExpirationTime('1h')
    .setIssuedAt()
    .sign(await jose.importPKCS8(privateKey!, 'RS256'));
    return jwt;
}