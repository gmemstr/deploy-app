import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'dart:convert';

class User {
  final String login;
  final String avatar;

  User({this.login, this.avatar});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      login: json['login'],
      avatar: json['avatar_url']
    );
  }
}

class Project {
  final String url;
  final String name;
  final String slug;

  Project({this.name, this.url, this.slug});

  factory Project.fromJson(Map<String, dynamic> json) {
    String vcs = (json['vcs'] == "github" ? "bb" : "gh");
    String slug = vcs + "/" + json['username'] + "/" + json['reponame'];
    return Project(
      url: json['vcs_url'],
      name: json['reponame'],
      slug: slug,
    );
  }
}

class BuildShallow {
  final int num;
  final bool oss;
  final String buildUrl;
  final String branch;
  final String triggeredBy;
  final String status;
  final DateTime startTime;
  final DateTime finishTime;

  BuildShallow(
      {this.num, this.oss, this.buildUrl, this.branch, this.triggeredBy, this.status, this.startTime, this.finishTime});

  factory BuildShallow.fromJson(Map<String, dynamic> json) {
    return BuildShallow(
      num: json['build_num'],
      oss: json['oss'],
      buildUrl: json['build_url'],
      branch: json['branch'],
      triggeredBy: json['user']['login'],
      status: json['status'],
      startTime: DateTime.parse(json["start_time"]),
      finishTime: DateTime.parse(json["stop_time"]),
    );
  }
}

class BuildDeep {
  final int num;
  final bool oss;
  final String buildUrl;
  final String branch;
  final String triggeredBy;
  final String status;
  final List<BuildStep> steps;
  final String commit;

  BuildDeep(
      {this.steps,
      this.num,
      this.oss,
      this.buildUrl,
      this.branch,
      this.triggeredBy,
      this.status,
      this.commit});

  factory BuildDeep.fromJson(Map<String, dynamic> json) {
    List<BuildStep> stepList = List();
    for (int i = 0; i < json["steps"].length; i++) {
      stepList.add(BuildStep.fromJson(json["steps"][i]));
    }

    String commit = "No commit message";
    if (json["all_commit_details"].length > 0) {
      commit = json["all_commit_details"][0]["subject"];
    }
    return BuildDeep(
      steps: stepList,
      num: json['build_num'],
      oss: json['oss'],
      buildUrl: json['build_url'],
      branch: json['branch'],
      triggeredBy: json['user']['login'],
      status: json['status'],
      commit: commit,
    );
  }
}

class BuildStep {
  final String name;
  final String command;
  final int exitCode;
  final String status;
  final String runtime;
  final bool background;
  final String log;

  BuildStep({this.name, this.command, this.exitCode, this.status, this.runtime, this.background, this.log});

  factory BuildStep.fromJson(Map<String, dynamic> json) {
    return BuildStep(
      log: json["actions"][0]["output_url"] ?? "no log found",
      name: json["name"],
      command: json["bash_command"] ?? "",
      exitCode: json["actions"][0]["exit_code"] ?? 10000,
      status: json["status"],
      runtime: json["runtime_in_ms"],
      background: json["background"],
    );
  }

}