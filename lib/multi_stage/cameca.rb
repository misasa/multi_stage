require 'rubygems'
require 'bindata'
module MultiStage::Cameca

  # typedef struct Polyatomique {
  #      int     Flag_chiffre;     /*  CHIFFRE ou ELEMENT */
  #      int     chiffre;     /* a remplir si c'est un chiffre */
  #      int     nb_elts;     /* nombre d'elts dans le polyatomique */
  #      int     nb_charges;     /* sans 0 , + = 1, ++ = 2 ,  */
  #      char     charge;          /* PLUS = '+'   MOINS = '-' */
  #      char     string[64];     /* le texte du polyatomique */
  #      char     notused[3];
  #      Tab_elts tab_elts[NB_MAX_ELTS_COMP]; /* tab des els composes */
  # } Polyatomique;

  #define NB_MAX_ELTS_COMP	5 /* nb max d'elts dans un polyatom */
  # typedef struct Tab_elts {
  #   int num_elt;  /* numero de l'elt de 1 à 103 */
  #   int num_isotop; /* numero de l'isotop de 0 à nbisotop-1*/
  #   int quantite; /* quantite de l'elt */
  # } Tab_elts;

  # typedef struct                    /* one analysis */
  # {
  #      int          analysis_type;     /* voir mc_defa.h */
  #      char          analysis_name[32];     /* voir mc_defa.c */
  #      int          sple_pos_x;     /* sample position X in micron */
  #      int          sple_pos_y;     /* sample position Y in micron */
  #      char           sple_name[32];
  #      Polyatomique     sple_matrice;     /* la matrice */
  #      char          filename[256];     /* analysis file */
  #      int          time_sche;     /* temps d'acq en sec */
  #      int          mc_type;     /* 0:previous 1:new */
  #      char          mc_file[256];     /* file contening mc */
  #      char          mc_dir[256];     /* directory of mc_file */
  #      int          instr_type;     /* 0:previous 1:snap */
  #      char          instr_file[256];/* file contening intrument status */
  #      char          instr_dir[256];     /* directory of instr_file */
  #      int          instr_create_time; /* temps creation fichier */
  #      /*union mcap     *v;*/          /* selon le type la structure */
  #      /*int          stop_ion_source;*//* 0:No 1:Yes */
  #      char          no_used[2580];
  # }Tab_analysis; /* size = 4096 */

  class TabElts < BinData::Record
    endian  :big
    int32   :num_elt, :initial_value => 0
    int32   :num_isotop, :initial_value => 0
    int32   :quantite, :initial_value => 1
  end

  class Polyatomique < BinData::Record
    endian  :big
    int32   :flag_chiffre, :initial_value => 1
    int32   :chiffre, :initial_value => 0
    int32   :nb_elts, :initial_value => 0
    int32   :nb_charges, :initial_value => 0
    string  :charge, :length => 1, :trim_padding => true, :initial_value => ""
    string  :string, :length => 64, :trim_padding => true, :initial_value => "0.000000"
    string  :notused, :length => 3, :trim_padding => true, :initial_value => ""
    array :tab_elts, :initial_length => 5 do
      tab_elts  :tab_elts
    end
  end

  class TabAnalysis < BinData::Record
    endian  :big
    int32   :analysis_type, :initial_value => 6
    string  :analysis_name, :length => 32, :trim_padding => true, :initial_value => "Isotopes"
    int32   :sple_pos_x, :initial_value => 0
    int32   :sple_pos_y, :initial_value => 0
    string  :sple_name, :length => 32, :trim_padding => true, :initial_value => "sample"
    polyatomique  :polyatomique
    string  :filename, :length => 256, :trim_padding => true, :initial_value => "sample.is"
    int32   :time_sche, :initial_value => 0
    int32   :mc_type, :initial_value => 0
    string  :mc_file, :length => 256, :trim_padding => true, :initial_value => "@Trace_CPX_Li160GdHf_FC.is"
    string  :mc_dir, :length => 256, :trim_padding => true, :initial_value => "/export/home/ims/data/raw_spec"
    int32   :instr_type, :initial_value => 1
    string  :instr_file, :length => 256, :trim_padding => true, :initial_value => "sample.pri"
    string  :instr_dir, :length => 256, :trim_padding => true, :initial_value => "/export/home/ims/data/chaintask"
    int32   :instr_create_time, :initial_value => 0
    string  :no_used, :length => 2580, :trim_padding => true, :initial_value => ""
  end
  
  # typedef struct
  # {
  #      char          nom_struct[16];     /* nom de la structure "Def_chain" */
  #      int          release;     /* historique 0 ,  1... */
  #      int          nb_analyses;
  #      char          dir[256];     /* directory de sauvegarde */
  #      char          file[64];     /* nom de fichier de sauvegarde */
  #      int          stop_ion_source;/* 0:No 1:Yes */
  #      int          primary_status_apply;     /* 0: Yes 1: No 28/6/96 */
  #      int          offset_x;     /* de -1000 a 1000 28/6/96 */
  #      int          offset_y;     /* de -1000 a 1000 28/6/96 */
  #      char          ion_source[8];     /* l'ion AP 3/7/96 */
  #      double          hv_primary;     /* hv primary 3/7/96 */
  #      char          no_used[648];      /* 660: avant 3/7/96 */
  #      Tab_analysis     *tab[MAX_NB_CHA];     /* table of analyses */
  # }Def_chain; /* sizeof = 1424 a partir release 1, avant 1420 3/7/96 */

  class DefChain < BinData::Record
    endian  :big
    string  :nom_struct, :length => 16, :trim_padding => true, :initial_value => "Def_chain"
    int32   :release, :initial_value => 1
    int32   :nb_analyses, :initial_value => 0
    string  :dir, :length => 256, :trim_padding => true, :initial_value => "/export/home/ims/data/raw_spec"
    string  :file, :length => 64, :trim_padding => true, :initial_value => "deleteme.cha"
    int32   :stop_ion_source, :initial_value => 0
    int32   :primary_status_apply, :initial_value => 0
    int32   :offset_x, :initial_value => 0
    int32   :offset_y, :initial_value => 0
    string  :ion_source, :length => 8, :trim_padding => true, :initial_value => "O -"
    double  :hv_primary, :initial_value => 0.0
    string  :no_used, :length => 648, :trim_padding => true, :initial_value => ""
    skip    :length => 4 * 100
    array :tab, :initial_length => :nb_analyses do
      tab_analysis  :tab_analysis
    end
    
    def to_point_data(class_no = 1)
      point_data = []
      self.snapshot[:tab].each do |tab|
        h = Hash.new
        h["Class"] = class_no
        h["Name"] = tab[:sple_name]
        h["X-Locate"] = tab[:sple_pos_x].to_f
        h["Y-Locate"] = tab[:sple_pos_y].to_f
        h["Data"] = nil
        point_data << h
      end
      point_data
    end
  end
  
  # #ifndef COMPILE_6F
  # 
  # typedef struct Sample_def   /* donnees de l'echantillon */
  # {
  #   char    name[80]; /* nom de l'echantillon **/
  #   int   x, y;   /* les positions */
  #   int   z;    /* JLK - 10/01/00 */
  #   int   x1;   /* no used */
  #   Polyatomique  matrice;  /* la matrice */
  #   char    data_proc_id[80]; /* Data process id,
  #              * JLK - 08/08/2000
  #              * Polyatomique poly;
  #              */
  #   char    code[80]; /* JLK - 09/08/2000 */
  #   char    shuttle_id[80]; /* JLK - 21/08/2000 */
  #   int   win_x, win_y; /* JLK - 21/08/2000 */
  #   int   spl_x, spl_y; /* JLK - 21/08/2000 */
  #   char    not_used[128];    /* not used */
  # }Sample_def;
  # 
  # #else
  # 
  # typedef struct    /* donnees de l'echantillon */
  # {
  #   char    name[80]; /* nom de l'echantillon **/
  #   int   x, y;   /* les positions */
  #   int   x1, y1;   /* no used */
  #   Polyatomique  matrice;  /* la matrice */
  #   Polyatomique  poly;   /* no used */
  # }Sample_def;
  # 
  # #endif
  class SampleDef_6F < BinData::Record
    endian  :big
    string  :name, :length => 80, :trim_padding => true, :initial_value => ""
    int32   :x, :initial_value => 0
    int32   :y, :initial_value => 0
    int32   :z, :initial_value => 0
    int32   :x1, :initial_value => 0
    polyatomique  :matrice
    string  :data_proc_id, :length => 80, :trim_padding => true, :initial_value => ""
    string  :code, :length => 80, :trim_padding => true, :initial_value => ""
    string  :shuttle_id, :length => 80, :trim_padding => true, :initial_value => ""
    int32   :win_x, :initial_value => 0
    int32   :win_y, :initial_value => 0
    int32   :spl_x, :initial_value => 0
    int32   :spl_y, :initial_value => 0
    string  :not_used, :length => 128, :trim_padding => true, :initial_value => ""
  end

  class SampleDef < BinData::Record
    endian  :big
    string  :name, :length => 80, :trim_padding => true, :initial_value => "sample"
    int32   :x, :initial_value => 0
    int32   :y, :initial_value => 0
    int32   :x1, :initial_value => 0
    int32   :y1, :initial_value => 0
    polyatomique  :matrice
    polyatomique  :poly
  end #size 384 byte
  
  # /* structure point  */
  # typedef struct
  #   {
  #   double x    ;         /* abcisse*/
  #   double y  ;         /* ordonnee*/
  #   }
  #   ibd_point;  
  class IbdPoint < BinData::Record
    endian  :big
    double  :x, :initial_value => 0.0
    double  :y, :initial_value => 0.0    
  end #size 16 byte
  
  
  # /* taille date  */
  # #define IBD_TAILLE_DAT 20   
  # /* taille commentaire */
  # #define IBD_TAILLE_COM 80   
  # /* nombre max de positions de reference.*/
  # #define IBD_MAX_REF 20
  # /* nombre max de liens possibles entre positions de reference.*/
  # #define IBD_REF_MAX_LIEN  IBD_MAX_REF  
  
  # /* structure une position de reference. */
  # typedef struct 
  #   {
  #   char    ibd_ref_com[IBD_TAILLE_COM];/*commentaire*/
  #   char    ibd_ref_dat[IBD_TAILLE_DAT];/*date posit. ref.*/
  #   ibd_point ibd_ref_posit;  /* position du manip a la capture.*/
  #   char  dummy[10];    /*effet de bord*/
  #   int ibd_ref_lien_nb;    /* nb de liens*/
  #   int ibd_ref_lien[IBD_REF_MAX_LIEN];/* no de zone ou est la posit. de ref.*/
  #   }
  #   ibd_ref;
  class IbdRef < BinData::Record
    endian :big
    string  :ibd_ref_com, :length => 80, :initial_value => ""
    string  :ibd_ref_dat, :length => 20, :initial_value => ""
#    string  :padding1, :length => 4
    ibd_point :ibd_ref_posit
    string  :dummy, :length => 10, :trim_padding => true, :initial_value => ""
    string  :padding1, :length => 4
    int32   :ibd_ref_lien_nb, :initial_value => 0
    array :ibd_ref_lien, :type => :uint32, :initial_length => 20
  end #size 210 byte
  # 80 + 20 + 4 + 16 + 10 + 4 + 4 * 20 = 214 byte
  
  # /* max de refs declarables. */
  # #define IBD_MAX_REF 20                        
  # 
  # /* structure liste des refs */
  # typedef struct
  #   {
  #   int ibd_nb_ref   ;          /* nombre de ref  */
  #   ibd_ref ibd_reflist[IBD_MAX_REF];/* list des refs */
  #   }
  #   ibd_stru_reflist;
  class IbdStruReflist < BinData::Record
  endian :big
#    int32   :x, :initial_value => 0
    int32 :ibd_nb_ref, :initial_value => 0
#    string  :padding, :length => 4
#    array :ibd_reflist, :type => ibd_ref, :length => 20 
    string  :padding, :length => 4
    array :ibd_reflist, :initial_length => 20 do
      ibd_ref  :ibd_ref
      string  :padding, :length => 2
    end
#    string :padding_o, :length => 10, :trim_padding => true, :initial_value => ""    
  end # 210 * 20 + 4 byte = 4204 byte
  #(214 + 2) * 20 + 4 + 4 = 4328 byte
  #4338 - 4328 = 10
  
  # /*  structure enr fichier positions de reference*/
  # typedef struct
  #   {
  #   ibd_stru_reflist  ibd_fil_reflist;
  #   }
  #   ibd_stru_enr_reflist;
  class IbdStruEnrReflist < BinData::Record
     ibd_stru_reflist :ibd_fil_reflist
  end

  # #define SEQ_MAX_ENR 1000
  # 
  # typedef struct
  #   {
  #   int nb_max_enr;
  #   int nb_enr;
  #   int taille_enr;
  #   int tab_enr[SEQ_MAX_ENR];
  #   int tab_trou[SEQ_MAX_ENR];
  #   } struct_entete_enr; # size 4 * 3 + 4 * 1000 + 4 * 1000 = 8012
  class StructEnteteEnr < BinData::Record
    endian  :big
    int32 :nb_max_enr
    int32 :nb_enr
    int32 :taille_enr
    array :tab_enr, :type => :uint32, :initial_length => 1000
    array :tab_trou, :type => :uint32, :initial_length => 1000    
  end

  # /* taille code version  */
  # #define IBD_TAILLE_CODE_VERSION 80    
  # 
  # /* taille code device */
  # #define IBD_TAILLE_CODE_DEVICE 80   
  # 
  # /* taille code version  */
  # #define IBD_TAILLE_CODE_FICHIER 80      
  # /* entete client commun a tous les fichiers*/
  # typedef struct
  #   {
  #   char ibd_version_code[IBD_TAILLE_CODE_VERSION];/* code version*/
  #   char ibd_device_code[IBD_TAILLE_CODE_DEVICE];/* code device*/
  #   char ibd_fich_code[IBD_TAILLE_CODE_FICHIER];/* code fichier*/
  #   }
  #   ibd_fil_stru_entete_cli; #80*3 = 240
  
  class IbdFilStruEnteteCli < BinData::Record
    endian  :big
    string  :ibd_version_code, :length => 80, :trim_padding => true, :initial_value => ""
    string  :ibd_device_code, :length => 80, :trim_padding => true, :initial_value => ""
    string  :ibd_fich_code, :length => 80, :trim_padding => true, :initial_value => ""    
  end
  # size 240 byte
  
  class Padding10 < BinData::Record
    string :padding, :length => 10, :trim_padding => true, :initial_value => ""
  end
  
  class TEST < BinData::Record
    endian :big  
    int32 :size_of_struct_entete_enr
    int32 :size_of_struct_ibd_fil_stru_entete_cli
    ibd_fil_stru_entete_cli :entete_cli
    struct_entete_enr :entete_enr
    #int32 :padding
    #int32 :padding2
    #ibd_stru_enr_reflist :ibd_stru_enr_reflist
    
    array :ibd_stru_enr_reflist, :initial_length => 7 do
      ibd_stru_enr_reflist :ibd_stru_enr_reflist
    end
  end

  class ReflistHead < BinData::Record
    endian :big  
    int32 :size_of_struct_entete_enr
    int32 :size_of_struct_ibd_fil_stru_entete_cli
    ibd_fil_stru_entete_cli :entete_cli
    struct_entete_enr :entete_enr
    #int32 :padding
    #int32 :padding2
    #ibd_stru_enr_reflist :ibd_stru_enr_reflist
    
#    array :ibd_stru_enr_reflist, :initial_length => 7 do
#      ibd_stru_enr_reflist :ibd_stru_enr_reflist
#    end
  end
  
end