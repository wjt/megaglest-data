!!ARBfp1.0
# bumpdsp.fp -- David HENRY
# Bump mapping with Diffuse and Specular components, and Parallax Mapping

TEMP tmp, eye, newTexCoords, normal, diffuse, specular;

PARAM diffuseColor = state.light[0].diffuse;
PARAM ambientColor = state.light[0].ambient;
PARAM specCoef = 8.0;

ATTRIB iTexCoords = fragment.texcoord[0];
ATTRIB iEyeVec = fragment.texcoord[1];
ATTRIB iHalfVec = fragment.texcoord[2];
ATTRIB iLightVec = fragment.texcoord[3];

OUTPUT oColor = result.color;

# Compute new texture coords with parallax mapping
# > float height = texture2D (heightMap, gl_TexCoord[0].st).r;
# > height = height * 0.04 - 0.02;
# > vec3 eye = normalize (eyeVec);
# > iTexCoords = gl_TexCoord[0].st + (eye.xy * height);
TEX  tmp, iTexCoords, texture[3], 2D;         # tmp = texture2D (heightMap, gl_TexCoord[0].st).r
MAD  tmp, tmp.x, 0.04, -0.02;                 # tmp = tmp.x * 0.04 - 0.02

DP3  eye.w, iEyeVec, iEyeVec;
RSQ  eye.w, eye.w;
MUL  eye.xyz, eye.w, iEyeVec;                 # normalize (eyePos)

MAD  newTexCoords, eye, tmp.x, iTexCoords;    # newTexCoords = eye * tmp.x + iTexCoords

# Fetch normal from normal map, expand to the [-1, 1] range, and normalize
# > vec3 normal = 2.0 * texture2D (normalMap, gl_TexCoord[0].st).rgb - 1.0;
# > normal = normalize (normal);
TEX  normal, newTexCoords, texture[2], 2D;    # normal = texture2D (normalMap, gl_TexCoord[0].st).rgb
MAD  normal, normal, 2.0, -1.0;               # normal = 2.0 * normal - 1.0

DP3  normal.w, normal, normal;
RSQ  normal.w, normal.w;
MUL  normal.xyz, normal.w, normal;            # normalize (normal)

# Compute diffuse lighting
# > vec3 diffuse = max (dot (iLightVec, normal), 0.0) * vec3 (gl_LightSource[0].diffuse);
# > diffuse = diffuse * texture2D (decalMap, iTexCoords).rgb;
DP3  tmp, iLightVec, normal;                  # tmp = dot (iLightVec, normal)
MAX  tmp, tmp, 0.0;                           # tmp = max (dot (iLightVec, normal), 0.0)
MUL  diffuse, tmp, diffuseColor;              # diffuse = tmp * gl_LightSource[0].diffuse
TEX  tmp, newTexCoords, texture[0], 2D;       # tmp = texture2D (decalMap, iTexCoords).rgb
MUL  diffuse, diffuse, tmp;                   # diffuse = diffuse * tmp

# Compute specular lighting
# > vec3 specularCoeff = texture2D (glossMap, iTexCoords).rgb;
# > float specfactor = max (dot (iHalfVec, normal), 0.0);
# > specfactor = pow (specfactor, 8.0);
# > vec3 specular = vec3 (specfactor) * specularCoeff;
TEX  specular, newTexCoords, texture[1], 2D;  # specular = texture2D (glossMap, iTexCoords).rgb
DP3  tmp.x, iHalfVec, normal;                 # tmp.x = dot (iHalfVec, normal)
MAX  tmp.x, tmp.x, 0.0;                       # tmp.x = max (dot (iHalfVec, normal), 0.0)
POW  tmp, tmp.x, specCoef.x;                  # tmp = pow (tmp.x, 8.0)
#MUL  specular, specular, tmp.x;              # specular = specular * tmp.x

# Output final color
# > gl_FragColor = vec4 (diffuse + specular, 1.0) + gl_LightSource[0].ambient;
#ADD  tmp, diffuse, specular;
MAD  tmp, specular, tmp.x, diffuse;           # tmp = specular * tmp.x + diffuse
ADD  oColor, tmp, ambientColor;               # oColor = diffuse + specular + ambiant

END
