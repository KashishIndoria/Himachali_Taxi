const config = {
    appName: 'Himachali Taxi',
    brandColor: '#d9534f',
    expireTime: '10 minutes'
};

const styles = {
    container: `
        font-family: 'Helvetica Neue', Arial, sans-serif;
        max-width: 600px;
        margin: 20px auto;
        padding: 30px;
        border: 1px solid #eaeaea;
        border-radius: 5px;
        background-color: #ffffff;
        box-shadow: 0 2px 5px rgba(0,0,0,0.05);
    `,
    logo: `
        text-align: center;
        margin-bottom: 25px;
    `,
    header: `
        color: #333333;
        text-align: center;
        margin-bottom: 30px;
        font-size: 24px;
        font-weight: 600;
    `,
    welcome: `
        color: #555555;
        text-align: center;
        margin-bottom: 25px;
        font-size: 20px;
    `,
    message: `
        font-size: 16px;
        color: #444444;
        line-height: 1.6;
        margin-bottom: 25px;
    `,
    otpContainer: `
        background-color: #f8f9fa;
        border-radius: 4px;
        padding: 15px;
        margin: 25px 0;
        text-align: center;
    `,
    otp: `
        font-size: 32px;
        color: ${config.brandColor};
        font-weight: bold;
        letter-spacing: 2px;
    `,
    button: `
        display: inline-block;
        padding: 12px 24px;
        background-color: ${config.brandColor};
        color: white;
        text-decoration: none;
        border-radius: 4px;
        margin: 20px 0;
    `,
    footer: `
        font-size: 14px;
        color: #888888;
        text-align: center;
        margin-top: 30px;
        padding-top: 20px;
        border-top: 1px solid #eaeaea;
    `
};

const otpEmailTemplate = (otp) => {
    return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${config.appName} - Email Verification</title>
    </head>
    <body>
        <div style="${styles.container}">
            <h1 style="${styles.header}">Email Verification</h1>
            <h2 style="${styles.welcome}">Welcome to ${config.appName}!</h2>
            
            <p style="${styles.message}">
                Thank you for registering with us. To ensure the security of your account, 
                please verify your email address using the OTP below:
            </p>

            <div style="${styles.otpContainer}">
                <div style="${styles.otp}">${otp}</div>
            </div>

            <div style="${styles.footer}">
                <p>This OTP will expire in ${config.expireTime}.</p>
                <p>If you didn't request this verification, please ignore this email.</p>
            </div>
        </div>
    </body>
    </html>
    `;
};

const successEmailTemplate = (name, role) => {
    return `
      <!DOCTYPE html>
      <html>
      <head>
          <meta charset="utf-8">
          <title>Account Created Successfully</title>
      </head>
      <body style="${styles.container}">
          <div style="${styles.header}">
              <h1>Welcome to Himachali Taxi!</h1>
          </div>
          
          <div style="${styles.message}">
              <p>Dear ${name},</p>
              <p>Congratulations! Your ${role} account has been successfully created and verified.</p>
              <p>You can now log in to your account and start using our services.</p>
              ${role === 'captain' 
                ? '<p>You can now start accepting ride requests and manage your availability through the app.</p>'
                : '<p>You can now book rides and enjoy our taxi services.</p>'
              }
          </div>
  
          <div style="${styles.footer}">
              <p>Thank you for choosing Himachali Taxi!</p>
              <p>If you have any questions, please contact our support team.</p>
          </div>
      </body>
      </html>
    `;
  };

module.exports = { 
    otpEmailTemplate, 
    successEmailTemplate
};