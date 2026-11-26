# AWS S3 Setup — TAPP

Bucket: **`tappfashion-beta-storage`**

## 1. Bucket
1. AWS Console → **S3** → open **`tappfashion-beta-storage`**.
2. **Properties** tab → note the **Region** (e.g. `ap-south-1`).
3. **Permissions** tab → **Block public access** → **Edit** → tick **Block all public access** → **Save** → type `confirm`.

## 2. Policy
1. Console → **IAM** → **Policies** → **Create policy** → **JSON** tab.
2. Paste this and **Create**, name it `tapp-s3-app`:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
         "Resource": "arn:aws:s3:::tappfashion-beta-storage/*"
       },
       {
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::tappfashion-beta-storage"
       }
     ]
   }
   ```

## 3. User + keys
1. IAM → **Users** → **Create user** → name `tapp-backend` → **Next**.
2. **Attach policies directly** → tick `tapp-s3-app` → **Create user**.
3. Open the user → **Security credentials** → **Create access key** → **Application running outside AWS** → **Create**.
4. Copy the **Access key ID** and **Secret access key** (shown once).

## 4. .env (`tapp-backend/.env`)
```bash
AWS_S3_BUCKET=tappfashion-beta-storage
AWS_REGION=<region from step 1>
AWS_ACCESS_KEY_ID=<access key id>
AWS_SECRET_ACCESS_KEY=<secret access key>
```
Restart the backend.

## 5. Check
Build a 3D model in the app → open the editor. If it loads, S3 works.
