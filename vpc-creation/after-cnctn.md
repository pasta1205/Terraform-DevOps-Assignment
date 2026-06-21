Once Terraform creates the IAM role and attaches:

```text id="jrnk6w"
AmazonSSMManagedInstanceCore
```

you don't SSH at all.

---

## Step 1: Verify Instance is Registered with SSM

Go to:

AWS Systems Manager

Then:

```text id="42a7ut"
Systems Manager
→ Fleet Manager
→ Managed Nodes
```

You should see:

```text id="j4qwr8"
Frontend
Backend
```

with status:

```text id="6qww3e"
Online
```

If the backend is not showing:

* Wait 2-3 minutes after EC2 creation.
* Verify the IAM role is attached.
* Verify NAT Gateway is working.

---

## Step 2: Start Session

Go to:

```text id="1jntsa"
Systems Manager
→ Session Manager
→ Start Session
```

Select:

```text id="4pwjab"
Backend
```

Click:

```text id="4x85j6"
Start Session
```

You'll get a terminal directly into the private EC2.

---

## Step 3: Verify MongoDB

Run:

```bash id="hh1m2p"
sudo systemctl status mongod
```

Expected:

```text id="vdtqse"
active (running)
```

Check port:

```bash id="r3dq6f"
sudo ss -tulpn | grep 27017
```

Expected:

```text id="z9rmha"
0.0.0.0:27017
```

---

## Step 4: Verify Frontend → Backend Connectivity

Open another SSM session to the frontend.

Install netcat:

```bash id="4iq4w0"
sudo dnf install -y nmap-ncat
```

Get backend IP:

```bash id="6nlszw"
hostname -I
```

on the backend.

Then on frontend:

```bash id="r55yl6"
nc -zv <backend-private-ip> 27017
```

Example:

```bash id="6mn29m"
nc -zv 10.0.2.88 27017
```

Expected:

```text id="dgbg7e"
Connected to 10.0.2.88:27017
```

---

## If Backend Doesn't Appear in Session Manager

On the EC2 page, verify:

### IAM Role

Instance should have:

```text id="y2y1qz"
SSMProfile
```

attached.

### NAT Gateway

Private route table should contain:

```text id="m2x4cr"
0.0.0.0/0 → NAT Gateway
```

### SSM Agent

Amazon Linux 2023 already includes SSM Agent.

Check from the frontend test instance:

```bash id="28jfe3"
sudo systemctl status amazon-ssm-agent
```

---

### Faster Check

Instead of navigating through Session Manager, go to:

```text id="4s77ye"
EC2
→ Instances
→ Select Backend
→ Connect
→ Session Manager
→ Connect
```

If everything is configured correctly, AWS opens a terminal directly to the private backend instance without any SSH keys.
