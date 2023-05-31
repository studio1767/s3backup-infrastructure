# user: ${user}
%{ for secret in secrets ~}
- id: ${secret.id}
  passphrase: ${secret.pass}
%{ endfor ~}

