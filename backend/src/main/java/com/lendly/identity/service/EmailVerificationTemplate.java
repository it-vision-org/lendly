package com.lendly.identity.service;

/**
 * Builds the HTML/plain-text bodies for the signup verification email. Kept
 * as static string builders (no templating engine) since the content is a
 * single, simple, lightweight message.
 */
final class EmailVerificationTemplate {

    private EmailVerificationTemplate() {
    }

    static String html(String code) {
        return """
            <!doctype html>
            <html>
              <body style="margin:0;padding:32px 16px;background-color:#F1F5F9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
                <table role="presentation" width="100%%" style="max-width:420px;margin:0 auto;background-color:#FFFFFF;border-radius:16px;padding:36px 32px;">
                  <tr>
                    <td style="text-align:center;">
                      <h1 style="margin:0 0 12px;font-size:20px;color:#0F172A;">Verify your email</h1>
                      <p style="margin:0 0 24px;font-size:14px;line-height:1.5;color:#475569;">
                        Your Flex verification code is:
                      </p>
                      <div style="display:inline-block;padding:16px 28px;background-color:#F1F5F9;border-radius:12px;font-size:32px;font-weight:700;letter-spacing:8px;color:#0F172A;font-family:'SFMono-Regular',Consolas,Menlo,monospace;">
                        %s
                      </div>
                      <p style="margin:24px 0 0;font-size:13px;line-height:1.5;color:#64748B;">
                        This code expires in 10 minutes.
                      </p>
                      <p style="margin:16px 0 0;font-size:12px;line-height:1.5;color:#94A3B8;">
                        If you didn't request this code, you can safely ignore this email.
                      </p>
                    </td>
                  </tr>
                </table>
              </body>
            </html>
            """.formatted(code);
    }

    static String text(String code) {
        return """
            Verify your email

            Your Flex verification code is:

            %s

            This code expires in 10 minutes.

            If you didn't request this code, you can safely ignore this email.
            """.formatted(code);
    }
}
