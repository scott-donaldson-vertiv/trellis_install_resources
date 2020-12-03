# Trellis™ Enterprise - Professional Services Installation Resources

## Introduction

Resources to supplement the existing Engineering Pre-Installation Check utility and RHEL Kickstarts for the purpose of increasing efficiency and deployment success and offer extended capabilities & security hardening not found in the Engineering sample kickstarts.

## Content

```bash
├── supplemental_preckecks
│   ├── documentation
│   ├── linux
│   │   ├── README.md
│   ├── windows
│   │   ├── README.md
│   ├── README.md
├── supplemental_Kickstarts
│   ├── Baseline
│   │   ├── x
│   ├── Enhanced
│   │   ├── ks_tie_rhel7-efi-stig.cfg
│   │   ├── ks_trellis_rhel7-efi-stig.cfg
│   ├── README.md
├── README.md
├── LICENSE.txt
└── .gitignore
```

#### Versions
| Release   | Release Date      | Notes                                                           |
|-----------|-------------------|-----------------------------------------------------------------|
| 1.2		| 2020/12/03		| Corrections to firewalld services in kickstart, corrections to baseline config shared memory to pass precheck. |
| 1.1		| 2020/08/12		| Updated supplemental_precheck linux for firewalld and other bugs |
| 1.0		| 2020/07/02		| Clean-up of resources, script names, copy right statements. Corrected Author, Contributors & Maintainers to be consistent and compliant with license requirements. |

## Support
These collections are provided to aid Vertiv Software Delivery, Services and
Software Delivery, Support teams, guidance and support for Postman - or
alternatives - is not provided.

| Release   | Support Status     | Notes                           | Trellis Compatibility |
|-----------|--------------------|---------------------------------|-----------------------|
| 1.2 			| Supported          | Fixes for 5.1.2 release.              | 5.1.x, 5.0.x          |
| 1.1 			| Supported          | Fixes for 5.1.1 release.              | 5.1.x, 5.0.x          |
| 1.0 			| Supported          | Initial Release                 | 5.1.x, 5.0.x          |

### License

Re-distribution is subject to the terms of the included license (LICENSE.MD).

### Authors & Contributors

| Name                | Organization        | Contact                                             |
|---------------------|---------------------|-----------------------------------------------------|
| Scott Donaldson     | Vertiv              | scott.donaldson@vertiv.com                          |
| Mark Zagorski       | Vertiv              | mark.zagorski@vertiv.com                            |
| Ray Daugherty       | Vertiv              | ray.daugherty@vertiv.com                            |
| Richard Golstein    | Emerson (Formerly)  | richard.golstein@emerson.com (DEFUNCT)              |
| Michael Santangelo  | Emerson (Formerly)  | michael.santangelo@emerson.com (DEFUNCT)            |

#### Maintainers
Feedback on function, errata and enhancements is welcome, this can be sent to the
following mailbox.

| Name                      | Organization      | Contact                                                          |
|---------------------------|-------------------|------------------------------------------------------------------|
| Professional Services     | Vertiv            | global.services.delivery.development@vertiv.com                  |

### Open Source Attributions

#### BSD 4-Clause
The following software are used in this product and are subject to the Berkeley Software Distribution 4-Clause ("BSD 4-Clause") as attached.
Vertiv notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
accordance with the terms and conditions of BSD 4-Clause attached. Therefore, if you obtain such source code, please read carefully the terms and conditions
of BSD 4-Clause.

- iperf

#### GPL

The following software are used in this product and are subject to the GNU General Public License ("GPL") as attached.
Vertiv notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
accordance with the terms and conditions of GPL attached. Therefore, if you obtain such source code, please read carefully the terms and conditions
of GPL.

#### LGPL

The following software are used in this product and are subject to the GNU Lesser General Public License ("LGPL") as attached.
Vertiv notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
accordance with the terms and conditions of LGPL attached. Therefore, if you obtain such source code, please read carefully the terms and conditions
of LGPL.

- 7-Zip

#### Microsoft Public License
The following software are used in this product and are subject to the Microsoft Public License ("Ms-PL") as attached.
Vertiv notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
accordance with the terms and conditions of Ms-PL attached. Therefore, if you obtain such source code, please read carefully the terms and
conditions of Ms-PL.

- PowerShell Community Extension
