{ lib
, stdenvNoCC
, callPackage
, fetchFromGitHub
, maubot
, python3
}:

let
  # pname: plugin id (example: xyz.maubot.echo)
  # version: plugin version
  # other attributes are passed directly to stdenv.mkDerivation
  buildMaubotPlugin = attrs@{ version, pname, ... }: stdenvNoCC.mkDerivation ({
    pluginName = "${pname}-v${version}.mbp";
    nativeBuildInputs = lib.optionals (attrs?nativeBuildInputs) attrs.nativeBuildInputs ++ [ maubot ];
    buildPhase = ''
      runHook preBuild

      mbc build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/maubot-plugins
      install -m 444 $pluginName $out/lib/maubot-plugins

      runHook postInstall
    '';
  } // (builtins.removeAttrs attrs ["genPassthru" "nativeBuildInputs"]));

  generated = callPackage ./generated.nix {
    inherit python3;
  };

  generatedPlugin = name: args:
    let
      entry = generated.${name};
      meta = if builtins.isString args then {
        description = args;
      }
      else if args?meta then args.meta
      else args;
      attrs = if builtins.isAttrs args && args?meta then builtins.removeAttrs args ["meta"] else {};
    in buildMaubotPlugin (entry // attrs // {
      meta = entry.meta // meta // (lib.optionalAttrs (meta?changelog) {
        changelog = "${entry.genPassthru.repoBase}/${args.changelog}";
      });
    });

  generatedPlugins = prefix: builtins.mapAttrs (k: generatedPlugin "${prefix}.${k}");

  plugins = {
    bzh.abolivier = generatedPlugins "bzh.abolivier" {
      autoreply = "Maubot plugin for an auto-reply bot";
    };
    casavant = {
      jeff = generatedPlugins "casavant.jeff" {
        trumptweet = "A plugin for Maubot that generates tweets from Trump";
      };
      tom = generatedPlugins "casavant.tom" {
        giphy = "Generates a gif given a search term, a plugin for Maubot for matrix";
        poll = "A plugin for maubot that creates a poll in a riot room and allows users to vote";
        reddit = "A simple maubot that corrects users when they enter a subreddit without including the entire link";
      };
    };
    coffee.maubot = generatedPlugins "coffee.maubot" {
      choose = "Maubot plugin to choose an option randomly";
      urlpreview = "A bot that responds to links with a link preview embed, using Matrix API to fetch meta tag";
    };
    com = {
      arachnitech = generatedPlugins "com.arachnitech" {
        weather = {
          description = "This is a maubot plugin that uses wttr.in to get a simple representation of the weather";
          changelog = "CHANGELOG.md";
        };
      };
      valentinriess = generatedPlugins "com.valentinriess" {
        hasswebhook = "A maubot to get Homeassistant-notifications in your favorite matrix room";
        mensa = "A maubot bot for the canteen at Otto-von-Guericke-Universität Magdeburg";
      };
    };
    de = {
      hyteck = generatedPlugins "de.hyteck" {
        alertbot = {
          description = "A bot that receives a webhook and forwards alerts to a matrix room";
          changelog = "CHANGELOG.md";
        };
      };
      yoxcu = generatedPlugins "de.yoxcu" {
        token = "A maubot to manage your synapse user registration tokens";
      };
    };
    lomion = generatedPlugins "lomion" {
      tmdb = {
        description = "A maubot to get information about movies from TheMovieDB.org";
        changelog = "release-note.md";
      };
    };
    me = {
      edwardsdean.maubot = generatedPlugins "me.edwardsdean.maubot" {
        metric = "A maubot plugin that will reply to a message with imperial units with the fixed metric units";
      };
      gogel.maubot = generatedPlugins "me.gogel.maubot" {
        redditpreview = "Maubot plugin that responds to a link of a reddit post with sub name and title. If the post is an image or video, it will upload it to the chat";
        wolframalpha = "Maubot plugin to search on Wolfram Alpha";
        youtubepreview = "Maubot plugin that responds to a YouTube link with the video title and thumbnail";
      };
      jasonrobinson = generatedPlugins "me.jasonrobinson" {
        pocket = {
          description = "A maubot plugin that integrates with Pocket";
          changelog = "CHANGELOG.md";
        };
      };
    };
    org = {
      casavant.jeff = generatedPlugins "org.casavant.jeff" {
        twilio = "Maubot plugin to bridge SMS in with Twilio";
      };
      jobmachine = generatedPlugins "org.jobmachine" {
        createspaceroom = "Maubot plugin to create a matrix room and include it as part of a matrix space";
        invitebot = "Maubot plugin for generating invite tokens via matrix-registration";
        join = "Maubot plugin to allow specific users to get a bot to join another room";
        kickbot = "Maubot plugin that tracks the last message timestamp of a user across any room that the bot is in, and generates a simple report";
        reddit = "Maubot plugin that fetches a random post (image or link) from a given subreddit)";
        tickerbot = "Maubot plugin to return basic financial data about stocks and cryptocurrencies";
        welcome = "Maubot plugin to send a greeting to people when they join rooms";
      };
    };
    pl.rom4nik.maubot = generatedPlugins "pl.rom4nik.maubot" {
      alternatingcaps = "A simple maubot plugin that repeats previous message in room using aLtErNaTiNg cApS";
    };
    xyz.maubot = generatedPlugins "xyz.maubot" {
      altalias = "A maubot that lets users publish alternate aliases in rooms";
      commitstrip = "A maubot plugin to view CommitStrips";
      dice = "A maubot plugin that rolls dice";
      echo = "A simple maubot plugin that echoes pings and other stuff";
      exec = "A maubot plugin to execute code";
      factorial = "A maubot plugin that calculates factorials";
      github = "A GitHub client and webhook receiver for maubot";
      gitlab = "A GitLab client and webhook receiver for maubot";
      karma = "A maubot plugin to track the karma of users";
      manhole = "A maubot plugin that provides a Python shell to access the internals of maubot";
      media = "A maubot plugin that posts MXC URIs of uploaded images";
      reactbot = "A maubot plugin that responds to messages that match predefined rules";
      reminder = "A maubot plugin to remind you about things";
      rss = "A RSS plugin for maubot";
      satwcomic = "A maubot plugin to view SatWComics";
      sed = "A maubot plugin to do sed-like replacements";
      songwhip = "A maubot plugin to post Songwhip links";
      supportportal = "A maubot plugin to manage customer support on Matrix";
      tex = "A maubot plugin to render LaTeX as SVG";
      translate = "A maubot plugin to translate words";
      xkcd = "A maubot plugin to view xkcd comics";

      # unofficial plugins using the same namespace...
      pingcheck = "Maubot plugin to track ping times against echo bot for Icinga passive checks";
      redactbot = "A maubot that responds to files being posted and redacts/warns all but a set of whitelisted mime types";
    };
  };
in
  {
    inherit buildMaubotPlugin;

    officialPlugins =
      builtins.filter
        (x: with plugins.xyz.maubot; x != pingcheck && x != redactbot)
        (lib.mapAttrsToList (k: v: v) plugins.xyz.maubot);

    allPlugins = builtins.concatLists (map (lib.mapAttrsToList (k: v: v)) [
      plugins.bzh.abolivier
      plugins.casavant.jeff
      plugins.casavant.tom
      plugins.coffee.maubot
      plugins.com.arachnitech
      plugins.com.valentinriess
      plugins.de.hyteck
      plugins.de.yoxcu
      plugins.lomion
      plugins.me.edwardsdean.maubot
      plugins.me.gogel.maubot
      plugins.me.jasonrobinson
      plugins.org.casavant.jeff
      plugins.org.jobmachine
      plugins.pl.rom4nik.maubot
      plugins.xyz.maubot
    ]);

    bzh = lib.recurseIntoAttrs {
      abolivier = lib.recurseIntoAttrs plugins.bzh.abolivier;
    };
    casavant = lib.recurseIntoAttrs {
      jeff = lib.recurseIntoAttrs plugins.casavant.jeff;
      tom = lib.recurseIntoAttrs plugins.casavant.tom;
    };
    coffee = lib.recurseIntoAttrs {
      maubot = lib.recurseIntoAttrs plugins.coffee.maubot;
    };
    com = lib.recurseIntoAttrs {
      arachnitech = lib.recurseIntoAttrs plugins.com.arachnitech;
      valentinriess = lib.recurseIntoAttrs plugins.com.valentinriess;
    };
    de = lib.recurseIntoAttrs {
      hyteck = lib.recurseIntoAttrs plugins.de.hyteck;
      yoxcu = lib.recurseIntoAttrs plugins.de.yoxcu;
    };
    lomion = lib.recurseIntoAttrs plugins.lomion;
    me = lib.recurseIntoAttrs {
      edwardsdean = lib.recurseIntoAttrs {
        maubot = lib.recurseIntoAttrs plugins.me.edwardsdean.maubot;
      };
      gogel = lib.recurseIntoAttrs {
        maubot = lib.recurseIntoAttrs plugins.me.gogel.maubot;
      };
      jasonrobinson = lib.recurseIntoAttrs plugins.me.jasonrobinson;
    };
    org = lib.recurseIntoAttrs {
      casavant = lib.recurseIntoAttrs {
        jeff = lib.recurseIntoAttrs plugins.org.casavant.jeff;
      };
      jobmachine = lib.recurseIntoAttrs plugins.org.jobmachine;
    };
    pl = lib.recurseIntoAttrs {
      rom4nik = lib.recurseIntoAttrs {
        maubot = lib.recurseIntoAttrs plugins.rom4nik.maubot;
      };
    };
    xyz = lib.recurseIntoAttrs {
      maubot = lib.recurseIntoAttrs plugins.xyz.maubot;
    };
  }
