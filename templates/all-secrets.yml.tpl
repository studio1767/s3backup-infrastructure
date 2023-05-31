%{ for user, secrets in all_secrets ~}
# user: ${user}
%{ for secret in secrets ~}
- id: ${secret.id}
  passphrase: ${secret.pass}
%{ endfor }
%{ endfor ~}

