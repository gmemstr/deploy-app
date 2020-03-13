/// This file contains classes for CircleCI v2 API endpoints ("pipelines").
///
/// https://circleci.com/docs/api/v2
import 'dart:convert';

import 'dart:io';

class Pipeline {
  final String id;
  final String projectSlug;
  final DateTime updated;
  final int number;
  final String state;
  final DateTime created;
  final Trigger trigger;
  final VersionControl vcs;
  final String branch;
  final List<Workflow> workflows;

  Pipeline(
      {this.id,
      this.projectSlug,
      this.updated,
      this.number,
      this.state,
      this.created,
      this.trigger,
      this.vcs,
      this.branch,
      this.workflows});

  static List<Pipeline> fromResponseJson(String body) {
    List<Pipeline> pipelines = [];
    var jData = json.decode(body);

    for (int i = 0; i < jData["items"].length; i++) {
      pipelines.add(fromJson(jData["items"][i]));
    }

    return pipelines;
  }

  static Pipeline fromJson(Map<String, dynamic> json) {
    String commit, commitSubject = "(no commit message)";
    if (json["vcs"].containsKey("commit")) {
      commit = json["vcs"]["commit"]["body"];
      commitSubject = json["vcs"]["commit"]["subject"];
    }
    Pipeline pipeline = Pipeline(
      id: json["id"],
      projectSlug: json["project_slug"],
      updated: DateTime.parse(json["updated_at"]),
      number: json["number"],
      state: json["state"],
      created: DateTime.parse(json["created_at"]),
      trigger: Trigger(
        received: DateTime.parse(json["trigger"]["received_at"]),
        type: json["trigger"]["type"],
        actorLogin: json["trigger"]["actor"]["login"],
        actorAvatar: json["trigger"]["actor"]["avatar_url"],
      ),
      vcs: VersionControl(
          repositoryUrl: json["vcs"]["origin_repository_url"],
          revision: json["vcs"]["revision"],
          providerName: json["vcs"]["provider_name"],
          commit: commit,
          commitSubject: commitSubject,
          isTag: json.containsKey(json["vcs"]["tag"]),
          branchTag: json.containsKey(json["vcs"]["tag"])
              ? json["vcs"]["tag"]
              : json["vcs"]["branch"]),
    );

    return pipeline;
  }
}

class Trigger {
  final DateTime received;
  final String type;
  final String actorLogin;
  final String actorAvatar;

  Trigger({this.received, this.type, this.actorLogin, this.actorAvatar});
}

class VersionControl {
  final String repositoryUrl;
  final String revision;
  final String providerName;
  final String commit;
  final String commitSubject;
  final bool isTag;
  final String branchTag;

  VersionControl(
      {this.repositoryUrl,
      this.revision,
      this.providerName,
      this.commit,
      this.commitSubject,
      this.isTag,
      this.branchTag});
}

class Workflow {
  final String id;
  final String name;
  final String status;
  final DateTime created;
  final DateTime stopped;
  final String pipelineId;
  final int pipelineNumber;
  final String slug;
  final List<Job> jobs;

  Workflow(
      {this.id,
      this.name,
      this.status,
      this.created,
      this.stopped,
      this.pipelineId,
      this.pipelineNumber,
      this.slug,
      this.jobs});
}

class Job {}
