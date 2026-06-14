# NanoClaw Discord Setup Guide

This guide provides instructions to securely set up NanoClaw inside a Docker container on this machine, integrating it directly with Discord.

## Prerequisites

Before starting, ensure you have the following ready:
1. **Docker**: NanoClaw uses Docker for container isolation. (The script will attempt to install it if missing, but having Docker Desktop/Engine ready is recommended).
2. **Discord Bot Token**: You need a Discord bot token to connect NanoClaw to Discord.
   - Go to the [Discord Developer Portal](https://discord.com/developers/applications).
   - Create a New Application.
   - Go to the "Bot" tab, click "Reset Token", and copy your new bot token.
   - Under "Privileged Gateway Intents", enable **Message Content Intent**, **Server Members Intent**, and **Presence Intent**.
   - Use the OAuth2 URL Generator to invite the bot to your server (Permissions needed: Read Messages, Send Messages).
3. **Anthropic API Key**: NanoClaw uses Claude. You'll need an API key from the [Anthropic Console](https://console.anthropic.com/).

## Step 1: Run the Interactive Setup

NanoClaw has been cloned to your machine in `~/lario-llms/nanoclaw`. To start the setup, you need to run the interactive setup script. This script must be run by you because it requires your sensitive API tokens.

Open a terminal and run:

```bash
cd ~/lario-llms/nanoclaw
bash nanoclaw.sh
```

## Step 2: Follow the Prompts

The setup script `nanoclaw.sh` is an interactive "clack-alike" installer that will:
1. Install necessary dependencies like `pnpm` and `Node` if they are missing.
2. Ensure Docker is running.
3. Authenticate with the Anthropic API (via OneCLI).
4. Build the Docker container for your isolated agent.

When the script asks which channel you would like to pair, **select Discord**.

It will then prompt you for:
- Your **Discord Bot Token**
- The **Discord Channel ID** (or server) you want the bot to operate in.

## Step 3: Enable Local Ollama or Bifrost Gateway Integration

You can configure NanoClaw to use your local models instead of Anthropic's cloud.

**Option A: Using the Bifrost Gateway (Recommended)**
Since you have Bifrost running locally, you can connect NanoClaw to it using the OpenCode provider.
After your basic setup is complete:
1. Open a terminal in `~/lario-llms/nanoclaw`
2. Run the command `claude`
3. Type `/add-opencode` to install the OpenCode provider skill.
4. Configure the endpoint to point to your Bifrost Gateway: `http://host.docker.internal:8080/v1`.
5. You can then use the models defined in your Bifrost config (e.g., `llama3.3:70b` or `qwen2.5-coder:32b`).

**Option B: Using Ollama Direct**
I have already configured a local caching proxy (`ollama-cch-proxy`) for you on this machine to ensure your Ollama instance runs quickly and uses prompt caching.
1. Run `claude`
2. Type `/add-ollama-provider` to automatically install the Ollama skill and configure your agent to point to your local Ollama instance (`http://host.docker.internal:11999`).
You can select models from your `ollama list`.

## Step 4: Managing NanoClaw

Once the setup is complete, your NanoClaw agent will be running securely in its own Docker container.

- **Triggering the Agent**: By default, you can trigger the agent in Discord by using the trigger word (e.g., `@Andy` or whatever you name your agent).
- **Customization**: NanoClaw uses an AI-native approach. If you want to modify your agent, just mention it in Discord (e.g., `@Andy change your trigger word to @Bot`).
- **Debugging**: If something fails, you can run `claude` in the `~/lario-llms/nanoclaw` directory and use the `/debug` command to let Claude Code diagnose any issues.

## Stopping or Uninstalling

If you ever need to uninstall or completely remove the NanoClaw containers and background services:

```bash
cd ~/lario-llms/nanoclaw
bash nanoclaw.sh --uninstall
```

This will safely remove the containers and system services without touching your other local configurations.
