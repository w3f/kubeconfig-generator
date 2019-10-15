kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
 name: vieweruser
subjects:
- kind: User
  name: ${USER}
  apiGroup: rbac.authorization.k8s.io
roleRef:
 kind: ClusterRole
 name: ${ROLE}
 apiGroup: rbac.authorization.k8s.io
