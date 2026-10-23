import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:musbx/data/services/musbx_api/client.dart';
import 'package:musbx/data/services/musbx_api_service.dart';
import 'package:pub_semver/pub_semver.dart';

class MockMusbxApiClient extends Mock implements MusbxApiClient {}

void main() {
  /// The clients handed out, by host URL.
  late Map<String, MockMusbxApiClient> clients;

  /// The host URLs a client was built for, in order.
  late List<String> built;

  /// A host that answers with [version].
  void answers(String host, String version) {
    when(
      clients[host]!.version,
    ).thenAnswer((_) async => Version.parse(version));
  }

  /// A host that cannot be reached.
  void unreachable(String host) {
    when(clients[host]!.version).thenThrow(ConnectionFailed());
  }

  MusbxApiService create(List<String> hosts) {
    clients = {for (final host in hosts) host: MockMusbxApiClient()};
    return MusbxApiService(
      hostUrls: hosts,
      version: VersionConstraint.parse("^0.5.0"),
      clientFor: (host) {
        built.add(host);
        return clients[host]!;
      },
    );
  }

  setUp(() {
    built = [];
  });

  test("contacts no host until a client is asked for", () {
    create(["a"]);
    expect(built, isEmpty);
  });

  group("client", () {
    test("is the first host that is compatible", () async {
      final api = create(["a", "b"]);
      answers("a", "0.5.1");
      answers("b", "0.5.0");

      expect(await api.client(), same(clients["a"]));
      expect(built, ["a"]);
    });

    test("skips hosts that cannot be reached", () async {
      final api = create(["a", "b"]);
      unreachable("a");
      answers("b", "0.5.0");

      expect(await api.client(), same(clients["b"]));
    });

    test("skips hosts with an incompatible version", () async {
      final api = create(["a", "b"]);
      answers("a", "0.4.2");
      answers("b", "0.5.0");

      expect(await api.client(), same(clients["b"]));
    });

    test("throws OutOfDate when a host answered but none fit", () async {
      final api = create(["a", "b"]);
      unreachable("a");
      answers("b", "0.6.0");

      await expectLater(api.client(), throwsA(isA<OutOfDate>()));
    });

    test("throws NoHostAvailable when no host answered", () async {
      final api = create(["a", "b"]);
      unreachable("a");
      unreachable("b");

      await expectLater(api.client(), throwsA(isA<NoHostAvailable>()));
    });

    test("throws NoHostAvailable when there are no hosts", () async {
      await expectLater(create([]).client(), throwsA(isA<NoHostAvailable>()));
    });

    test("is found once and then reused", () async {
      final api = create(["a"]);
      answers("a", "0.5.0");

      final first = await api.client();
      expect(await api.client(), same(first));
      expect(built, ["a"]);
      verify(clients["a"]!.version).called(1);
    });

    test("is shared by callers asking during a search", () async {
      final api = create(["a"]);
      final version = Completer<Version>();
      when(clients["a"]!.version).thenAnswer((_) => version.future);

      final first = api.client();
      final second = api.client();
      version.complete(Version.parse("0.5.0"));

      expect(await first, same(await second));
      expect(built, ["a"]);
    });

    test("is searched for again after a failed search", () async {
      final api = create(["a"]);
      unreachable("a");
      await expectLater(api.client(), throwsA(isA<NoHostAvailable>()));

      answers("a", "0.5.0");
      expect(await api.client(), same(clients["a"]));
      expect(built, ["a", "a"]);
    });
  });
}
