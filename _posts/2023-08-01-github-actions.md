---
layout: posts
title: GitHub Actions for Continuous Deployment
---

[GitHub Actions](https://github.com/features/actions){:target="_blank"} allows you to automate many facets of a project, whether you want to implement some automated testing via a continuous integration model, deploy a project automatically, or manage aspects of your GitHub repository itself. There are pricing tiers, but I find the free tier to be very generous for my needs; it includes 2000 minutes of runtime per month.

I recently setup this very website to build and deploy automatically via GitHub Actions upon a push. This is a huge advantage because I don't need to worry about building the static Jekyll site and then uploading the generated files to my web host every single time I want to make a change. Also, I don't need to ensure I have the full tool-chain installed on my workstation. All I have to do to deploy a site change is write my post, commit, and push the change to GitHub.

### Local Testing
Although local testing isn't strictly necessary, and you can just test your Actions live by triggering the appropriate trigger, I do find local testing to be a bit more convenient/reassuring. When testing locally you can setup test specific parameters. For local testing of GitHub Actions, I really like [nektos/act](https://github.com/nektos/act){:target="_blank"}.

It's interesting to know that GitHub leverages [Docker](https://www.docker.com/){:target="_blank"} containers to run your Actions. Act also uses Docker in order to allow you to test your Actions locally. Full install instructions can be found in the Act repository, but you'll need Docker installed and running as a prerequisite. You can install Act conveniently via [Homebrew](https://brew.sh/){:target="_blank"}.

Once installed, to trigger Act with a default (push) event, you simply need to run:
```
act
```

It is possible to setup secrets with Act as well. We'll talk about this a bit later, but if you have a file storing your secrets, you can use the following to run Act with your secrets:
```
act --secret-file .secrets
```

### Getting Started

If we assume you already have a GitHub repository, you'll need to create a directory with a yaml file.
```
mkdir -p .github/actions
touch .github/actions/deploy.yaml
```

You can view the actual [`deploy.yaml` file for this very website](https://github.com/mstathers/stathers-net/blob/master/.github/workflows/deploy.yml){:target="_blank"}, but I've also included it in full below for reference.

{% highlight yaml %}{% raw %}
name: Deploy

on:
  workflow_dispatch:
  push:
    branches:
      - master
env:
  AWS_DEFAULT_REGION: us-west-2

jobs:
  build:
    runs-on: ubuntu-22.04

    steps:
      - uses: actions/checkout@v3

      - name: Install Dependencies
        run: |
          sudo apt update &&
          sudo apt install -y ruby-rubygems ruby-dev awscli &&
          sudo gem install --no-document jekyll jekyll-paginate

      - run: jekyll build

      - name: Sync to S3
        run: |
          aws s3 sync --delete _site/ s3://${{ env.AWS_S3_BUCKET }}/ \
          --acl public-read --metadata-directive REPLACE \
          --cache-control max-age=300 --no-progress
        env:
          AWS_S3_BUCKET: ${{ secrets.AWS_S3_BUCKET }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
{% endraw %}{% endhighlight %}

I'll step through sections of this file and explain it all below.

I have named the "workflow" as Deploy. The name doesn't really matter, but as your Actions become more complicated it might be a good idea to break them up with a good naming scheme.

I have configured the Action to trigger on push to the master branch. I have also allowed for a manual trigger via `workflow_dispatch` - this displays a button inside the GitHub Actions UI on the repository website.

I set a global environment variable which is used later.

I configured this Action to run on an Ubuntu 22.04 container. GitHub offers Windows, macOS and Ubuntu containers, a full list can be viewed [here](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources){:target="_blank"}. I do recommend "pinning" your container to a specific version rather than just using `latest`, as this will avoid unforeseen changes as what is latest changes.

It is possible to use pre-built Actions that other people have published on the [GitHub Marketplace](https://github.com/marketplace?type=actions){:target="_blank}. I use one of these here called `actions/checkout@v3` to checkout the code in my repo into the Docker container so that I can use it later.

Actions allow for full flexibility though with the use of `run` commands. In my case, I use these run commands to install some dependencies, build my Jekyll static site and then sync the generated static site code up to AWS S3. You can configure multi-line run commands, you don't even have to give them all bespoke names, and you can do things like setup environment variables which are only available for specific steps.

### Secrets
You'll notice that my entire GitHub Action has the same public visibility as the rest of my repository. When I'm syncing my files to AWS S3, I don't want the whole world to know my secret AWS keys. Fortunately GitHub allows us to setup [Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets){:target="_blank"}! These are configured in the Settings page of your repository and can be accessed by your Action via a variable - `{% raw %}${{ secrets.NAME_OF_SECRET }}{% endraw %}`. You can see that I use three of these secrets in my deploy Action. Conveniently, if the secret is ever printed to the console of the Action, GitHub with automatically obfuscate the secret for you.

### Running
As you may have figured out, your Action will be triggered via the condition you have configured. You can monitor your running Action, or view previously ran Actions by browsing to the [Actions page of your repository](https://github.com/mstathers/stathers-net/actions){:target="_blank"}. Successful runs are marked with a happy green check mark, but in case of failure, this page is very useful for troubleshooting issues.

### Conclusion
GitHub Actions are very powerful and incredibly flexible. There are a [multitude of triggers available](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows){:target="_blank"} and your imagination is the limit. Also, on the enterprise side, you can operate your own "runners". These [self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners){:target="_blank"} allow you complete control over the underlying infrastructure, as well as giving you the option to operate with your own custom containers. 

I hope you find GitHub Actions useful for your CI/CD needs.
