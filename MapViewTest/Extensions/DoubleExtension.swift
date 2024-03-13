// DoubleExtension.swift
// Created by Marc Lütke on 10.03.24.
//
// Copyright, 2023 - GapLabs, Schortens, Germany
// All rights reserved

import Foundation

extension Double{
    func toRadiant() -> Double{
        return self / 180 * Double.pi
    }
}
