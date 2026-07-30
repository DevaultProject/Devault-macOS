// Copyright © 2026 Devault. All rights reserved

import Foundation
import Testing

@testable import DVDomain

@Suite("JSONCredentialDetector")
struct JSONCredentialDetectorTests {
    private let sut = JSONCredentialDetector()
    private let context = StubDetectorContext()

    @Test("type=service_account → GCP Service Account · project_id/client_email 파싱")
    func gcpServiceAccount() {
        let raw = """
            {
              "type": "service_account",
              "project_id": "my-gcp-project",
              "client_email": "svc@my-gcp-project.iam.gserviceaccount.com"
            }
            """
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "GCP Service Account")
        #expect(result?.candidates.first?.confidence == .high)
        guard case .json(let info) = result?.metadata else {
            Issue.record("expected .json")
            return
        }
        #expect(info.kind == .gcpServiceAccount)
        #expect(info.projectId == "my-gcp-project")
        #expect(info.clientEmail == "svc@my-gcp-project.iam.gserviceaccount.com")
    }

    @Test("service_account + firebase 문자열 포함 → Firebase Service Account")
    func firebaseServiceAccount() {
        let raw = """
            {
              "type": "service_account",
              "project_id": "my-firebase-app",
              "client_email": "svc@my-firebase-app.iam.gserviceaccount.com"
            }
            """
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Firebase Service Account")
        guard case .json(let info) = result?.metadata else {
            Issue.record("expected .json")
            return
        }
        #expect(info.kind == .firebaseServiceAccount)
    }

    @Test("installed 하위 client_id → Google OAuth Client + redirect_uris 파싱")
    func googleOAuthInstalled() {
        let raw = """
            {
              "installed": {
                "client_id": "12345.apps.googleusercontent.com",
                "client_secret": "GOCSPX-xyz",
                "redirect_uris": ["http://localhost", "urn:ietf:wg:oauth:2.0:oob"]
              }
            }
            """
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Google OAuth Client")
        guard case .json(let info) = result?.metadata else {
            Issue.record("expected .json")
            return
        }
        #expect(info.kind == .googleOAuthClient)
        #expect(info.clientId == "12345.apps.googleusercontent.com")
        #expect(info.redirectUris.count == 2)
    }

    @Test("web 하위 client_id도 Google OAuth Client")
    func googleOAuthWeb() {
        let raw = """
            {
              "web": {
                "client_id": "web-abc.apps.googleusercontent.com",
                "client_secret": "s"
              }
            }
            """
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "Google OAuth Client")
    }

    @Test("aws_access_key_id 포함 → AWS Credentials")
    func awsCredentials() {
        let raw = """
            {
              "default": {
                "aws_access_key_id": "AKIAIOSFODNN7EXAMPLE",
                "aws_secret_access_key": "wJalrXUtnFEMI/K7MDENG"
              }
            }
            """
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "AWS Credentials")
        guard case .json(let info) = result?.metadata else {
            Issue.record("expected .json")
            return
        }
        #expect(info.kind == .awsCredentials)
    }

    @Test("client_id + client_secret만 있으면 Generic OAuth (.medium)")
    func genericOAuth() {
        let raw = """
            {
              "client_id": "generic-app",
              "client_secret": "shhh"
            }
            """
        let result = sut.detect(.testing(raw), context: context)
        #expect(result?.candidates.first?.service == "OAuth Client Credentials")
        #expect(result?.candidates.first?.confidence == .medium)
    }

    @Test("JSON이 아니면 nil")
    func plainTextIsNil() {
        let result = sut.detect(.testing("not-a-json"), context: context)
        #expect(result == nil)
    }

    @Test("최상위가 array이면 nil (dict 아님)")
    func arrayRootIsNil() {
        let result = sut.detect(.testing("[1, 2, 3]"), context: context)
        #expect(result == nil)
    }

    @Test("JSON은 맞지만 credential 힌트 없으면 nil")
    func unrelatedJSONIsNil() {
        let result = sut.detect(.testing(#"{"foo": "bar"}"#), context: context)
        #expect(result == nil)
    }
}

private struct StubDetectorContext: DetectorContext {
    func detect(_ value: SensitiveString) -> DetectionResult { .none }
}
